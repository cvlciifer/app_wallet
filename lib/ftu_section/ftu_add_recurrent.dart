import 'dart:math' as math;

import 'package:app_wallet/library_section/main_library.dart';

class _HolePainter extends CustomPainter {
  final Rect holeRect;
  final double borderRadius;
  final Color overlayColor;

  _HolePainter({required this.holeRect, this.borderRadius = 8.0, required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, paint);
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius)), clearPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HolePainter old) {
    return old.holeRect != holeRect || old.borderRadius != borderRadius || old.overlayColor != overlayColor;
  }
}

class FTUAddRecurrentPage extends StatefulWidget {
  const FTUAddRecurrentPage({Key? key}) : super(key: key);

  @override
  State<FTUAddRecurrentPage> createState() => _FTUAddRecurrentPageState();
}

class _FTUAddRecurrentPageState extends State<FTUAddRecurrentPage> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Elige categoría');
  final _amountController = TextEditingController();
  int _selectedDay = DateTime.now().day;
  int _selectedMonths = 3;

  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _amountKey = GlobalKey();
  final GlobalKey _dayKey = GlobalKey();
  final GlobalKey _monthsKey = GlobalKey();
  final GlobalKey _submitKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runFTUSequence();
    });
  }

  Future<void> _runFTUSequence() async {
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      await _showOverlayForKey(_titleKey, title: 'Título', message: 'Nombre que identifica este gasto recurrente.');
      await _showOverlayForKey(_categoryKey, title: 'Categoría', message: 'Selecciona la categoría del gasto.');
      await _showOverlayForKey(_amountKey, title: 'Precio', message: 'Introduce el monto del pago recurrente.');
      await _showOverlayForKey(_dayKey, title: 'Día', message: 'El día del mes en que se repetirá el pago.');
      await _showOverlayForKey(_monthsKey, title: 'Meses', message: 'Cantidad de meses que durará el recurrente.');
      await _showOverlayForKey(_submitKey,
          title: 'Crear Recurrente', message: 'Para Guardar tu recurrente, presiona este botón.', isFinalStep: true);
    } catch (_) {}
  }

  Future<void> _showOverlayForKey(GlobalKey key,
      {required String title, required String message, bool isFinalStep = false}) async {
    try {
      final ctx = key.currentContext;
      if (ctx == null) return;
      try {
        await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.3);
      } catch (_) {}

      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;
      final targetPos = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;

      final popupCtx = Navigator.of(context, rootNavigator: true).overlay?.context ?? context;

      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'recurrent_ftu',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, a1, a2) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HolePainter(
                      holeRect: Rect.fromLTWH(
                        targetPos.dx - 8,
                        targetPos.dy - 8,
                        targetSize.width + 16,
                        targetSize.height + 16,
                      ),
                      borderRadius: 8.0,
                      overlayColor: AwColors.black.withOpacity(0.45),
                    ),
                  ),
                ),
                Positioned(
                  left: (() {
                    final screenW = MediaQuery.of(context).size.width;
                    final popupW = math.min(320, screenW - 32);
                    return (screenW - popupW) / 2;
                  })(),
                  top: (() {
                    final screenH = MediaQuery.of(context).size.height;
                    const popupApproxH = 140.0;
                    final preferAbove = targetPos.dy - popupApproxH - 12;
                    if (preferAbove >= 16) return preferAbove;
                    final preferBelow = targetPos.dy + targetSize.height + 12;
                    final maxTop = screenH - popupApproxH;
                    return preferBelow > maxTop ? maxTop : preferBelow;
                  })(),
                  child: Container(
                    width: math.min(320, MediaQuery.of(context).size.width - 32),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AwColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AwColors.black.withOpacity(0.18), blurRadius: 8)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AwText.bold(title, size: AwSize.s14),
                        AwSpacing.s6,
                        AwText.normal(message, size: AwSize.s12, color: AwColors.modalGrey),
                        AwSpacing.s10,
                        Row(
                          children: [
                            Expanded(
                              child: WalletButton.primaryButton(
                                buttonText: 'Entendido',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  if (isFinalStep) {
                                    try {
                                      // Navegar de vuelta al home para continuar con el tutorial de estadísticas
                                      Navigator.of(popupCtx).pushNamedAndRemoveUntil(
                                        '/home-page',
                                        (r) => false,
                                        arguments: {'continueFTUToStatistics': true},
                                      );
                                    } catch (_) {}
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold('Gasto Recurrente', color: AwColors.white),
        showBackArrow: true,
        barColor: AwColors.appBarColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TicketCard(
            notchDepth: 12,
            elevation: 8,
            color: AwColors.white,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AwSpacing.s12,
              const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.attach_money, color: AwColors.appBarColor, size: AwSize.s26),
                AwSpacing.w12,
                Expanded(child: AwText.bold('Crear gasto recurrente', size: AwSize.s20, color: AwColors.appBarColor)),
              ]),
              AwSpacing.s6,
              CustomTextField(
                  controller: _titleController,
                  label: 'Título',
                  maxLength: 50,
                  hideCounter: true,
                  flat: false,
                  key: _titleKey),
              AwSpacing.s12,
              Container(
                  key: _categoryKey,
                  child: CategoryPicker(
                      controller: _categoryController,
                      selectedCategory: Category.comidaBebida,
                      selectedSubcategoryId: null,
                      onSelect: (c, s, d) {})),
              AwSpacing.m,
              Row(children: [
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AwColors.greyLight, borderRadius: BorderRadius.circular(8)),
                    child: const AwText.bold('CLP \$')),
                const SizedBox(width: 12),
                Expanded(
                    child: CustomTextField(
                        key: _amountKey,
                        controller: _amountController,
                        label: 'Precio',
                        keyboardType: TextInputType.number,
                        inputFormatters: NumberFormatHelper.getAmountFormatters(),
                        flat: false)),
              ]),
              AwSpacing.s20,
              const AwText.bold('Día del mes', color: AwColors.boldBlack),
              AwSpacing.s,
              Container(key: _dayKey, child: _buildDayGrid()),
              AwSpacing.m,
              Row(children: [
                const AwText.bold('Meses', color: AwColors.boldBlack),
                AwSpacing.s12,
                Container(
                    key: _monthsKey,
                    child: DropdownButton<int>(
                        value: _selectedMonths,
                        items: List.generate(11, (i) => i + 2)
                            .map((m) => DropdownMenuItem(value: m, child: AwText.normal(m.toString())))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedMonths = v ?? 3))),
              ]),
              AwSpacing.s20,
              Container(
                key: _submitKey,
                child: WalletButton.primaryButton(
                    buttonText: 'Agregar Recurrente',
                    onPressed: () {
                      try {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home-page',
                          (r) => false,
                          arguments: {'continueFTUToStatistics': true},
                        );
                      } catch (_) {}
                    }),
              ),
              AwSpacing.s30,
            ]),
          ),
          AwSpacing.s40,
        ]),
      ),
    );
  }

  Widget _buildDayGrid() {
    const int maxDay = 31;
    final items = List<int>.generate(maxDay, (i) => i + 1);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((d) {
        final selected = d == _selectedDay;
        return GestureDetector(
          onTap: () => setState(() => _selectedDay = d),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: selected ? AwColors.blue : AwColors.greyLight, borderRadius: BorderRadius.circular(6)),
            child: AwText.normal(d.toString(), color: selected ? AwColors.white : AwColors.boldBlack),
          ),
        );
      }).toList(),
    );
  }
}
