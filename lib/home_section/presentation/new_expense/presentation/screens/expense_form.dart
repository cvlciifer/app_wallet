import 'package:app_wallet/library_section/main_library.dart';
import 'dart:math' as math;

class _HolePainter extends CustomPainter {
  final Rect holeRect;
  final double borderRadius;
  final Color overlayColor;

  _HolePainter(
      {required this.holeRect,
      this.borderRadius = 8.0,
      required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, paint);
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(
        RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius)),
        clearPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HolePainter old) {
    return old.holeRect != holeRect ||
        old.borderRadius != borderRadius ||
        old.overlayColor != overlayColor;
  }
}

class ExpenseForm extends StatefulWidget {
  final Function(Expense) onSubmit;
  final Expense? initialExpense;
  final bool showFTUOnOpen;

  const ExpenseForm({
    super.key,
    required this.onSubmit,
    this.initialExpense,
    this.showFTUOnOpen = false,
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Elige categoría');
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  Category _selectedCategory = Category.comidaBebida;
  String? _selectedSubcategoryId;
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _amountKey = GlobalKey();
  final GlobalKey _dateKey = GlobalKey();
  final GlobalKey _submitKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    final init = widget.initialExpense;
    if (init != null) {
      _titleController.text = init.title;
      _selectedDate = init.date;
      _selectedCategory = init.category;
      _selectedSubcategoryId = init.subcategoryId;

      _amountController.text =
          NumberFormatHelper.formatAmount(init.amount.toInt().toString());
      _categoryController.text = init.category.toString().split('.').last;
    } else if (widget.showFTUOnOpen) {
      _titleController.text = 'Cuenta';
      _amountController.text = NumberFormatHelper.formatAmount('12345');
      _selectedCategory = Category.comidaBebida;
      _categoryController.text = 'Comida y Bebida';
    }

    _selectedDate ??= DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (widget.showFTUOnOpen) {
          _runFTUSequence();
        }
      } catch (_) {}
    });
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
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            TicketCard(
              notchDepth: 12,
              elevation: 10,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AwSpacing.s12,
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: AwColors.appBarColor,
                        size: AwSize.s26,
                      ),
                      AwSpacing.w12,
                      Expanded(
                        child: AwText.bold(
                          'Agrega un nuevo gasto',
                          size: AwSize.s20,
                          color: AwColors.appBarColor,
                        ),
                      ),
                    ],
                  ),
                  AwSpacing.s6,
                  const AwText(
                    text:
                        'Registra un gasto. Puedes elegir Título, Categoría, Precio y Fecha.',
                    color: AwColors.blueGrey,
                    size: AwSize.s14,
                    textAlign: TextAlign.left,
                  ),
                  AwSpacing.xs,
                  Container(key: _titleKey, child: _buildTitle()),
                  AwSpacing.s12,
                  Container(
                    key: _categoryKey,
                    child: CategoryPicker(
                      controller: _categoryController,
                      selectedCategory: _selectedCategory,
                      selectedSubcategoryId: _selectedSubcategoryId,
                      onSelect: _selectCategory,
                    ),
                  ),
                  AwSpacing.s24,
                  Container(
                      key: _amountKey,
                      child: AmountInput(
                          controller: _amountController,
                          onChanged: _handleAmountChange)),
                  AwSpacing.s24,
                  Container(
                      key: _dateKey,
                      child: DateSelector(
                          selectedDate: _selectedDate,
                          onTap: _presentDatePicker)),
                  AwSpacing.s20,
                  Container(
                    key: _submitKey,
                    child: WalletButton.primaryButton(
                      buttonText: 'Añadir Gasto',
                      onPressed: _submitForm,
                    ),
                  ),
                  AwSpacing.s30,
                ],
              ),
            ),
            AwSpacing.s40,
          ],
        ),
      ),
    );
  }

  Future<void> _runFTUSequence() async {
    try {
      await Future.delayed(const Duration(milliseconds: 250));
      await _showOverlayForKey(_titleKey,
          title: 'Título',
          message: 'Aquí puedes ingresar el título del gasto.');
      await _showOverlayForKey(_categoryKey,
          title: 'Categoría', message: 'Selecciona la categoría del gasto.');
      await _showOverlayForKey(_amountKey,
          title: 'Precio', message: 'Ingresa el monto del gasto aquí.');
      await _showOverlayForKey(_dateKey,
          title: 'Fecha', message: 'Selecciona la fecha del gasto.');
      await _showOverlayForKey(_submitKey,
          title: 'Añadir Gasto',
          message: 'Para guardar tu gasto presiona este botón.');
    } catch (_) {}
  }

  Future<void> _showOverlayForKey(GlobalKey key,
      {required String title,
      required String message,
      String continueText = 'Continuar'}) async {
    try {
      final ctx = key.currentContext;
      if (ctx == null) return;
      try {
        await Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 300), alignment: 0.3);
      } catch (_) {}

      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;
      final targetPos = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;

      final popupCtx =
          Navigator.of(context, rootNavigator: true).overlay?.context ??
              context;

      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'expense_form_ftu',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, a1, a2) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AbsorbPointer(
                    absorbing: true,
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
                ),
                Positioned(
                  left: targetPos.dx - 8,
                  top: targetPos.dy - 8,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: targetSize.width + 16,
                      height: targetSize.height + 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AwColors.appBarColor, width: 3),
                      ),
                      child: const SizedBox.shrink(),
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
                    width:
                        math.min(320, MediaQuery.of(context).size.width - 32),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AwColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: AwColors.black.withOpacity(0.18),
                            blurRadius: 8)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AwText.bold(title, size: AwSize.s14),
                        AwSpacing.s6,
                        AwText.normal(message,
                            size: AwSize.s12, color: AwColors.modalGrey),
                        AwSpacing.s10,
                        Row(
                          children: [
                            Expanded(
                              child: WalletButton.primaryButton(
                                buttonText: continueText,
                                onPressed: () async {
                                  Navigator.of(context).pop();

                                  try {
                                    if (widget.showFTUOnOpen &&
                                        key == _submitKey) {
                                      _submitForm();
                                    }
                                  } catch (_) {}
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

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final lastDate = DateTime(now.year + 1, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (!mounted) return;
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _handleAmountChange(String value) {
    final formatted = NumberFormatHelper.formatAmount(value);
    if (formatted != _amountController.text) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _submitForm() {
    final numericValue =
        _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final enteredAmount = int.tryParse(numericValue);
    final amountIsInvalid = enteredAmount == null ||
        enteredAmount <= 0 ||
        enteredAmount > 999999999999;

    final titleEmpty = _titleController.text.trim().isEmpty;
    final dateEmpty = _selectedDate == null;

    if (titleEmpty || amountIsInvalid || dateEmpty) {
      final missing = <String>[];
      if (titleEmpty) missing.add('Título');
      if (amountIsInvalid) missing.add('Precio válido (> 0)');
      if (dateEmpty) missing.add('Fecha');

      final details = 'Por favor ingrese: ${missing.join(', ')}.';
      _showValidationDialog(details);
      return;
    }

    final expense = Expense(
      title: _titleController.text.trim(),
      amount: enteredAmount.toDouble(),
      date: _selectedDate!,
      category: _selectedCategory,
      subcategoryId: _selectedSubcategoryId,
    );

    widget.onSubmit(expense);
  }

  void _showValidationDialog([String? details]) {
    final contentText =
        details ?? 'Asegúrese de ingresar un título, monto y fecha válidos.';
    final dialogContent = Platform.isIOS
        ? CupertinoAlertDialog(
            title: const AwText.bold('Entrada no válida',
                color: AwColors.boldBlack),
            content: AwText(text: contentText),
            actions: [
              WalletButton.primaryButton(
                buttonText: 'Cerrar.',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          )
        : AlertDialog(
            title: const AwText.bold('Entrada no válida',
                color: AwColors.boldBlack),
            content: AwText(
              text: contentText,
              color: AwColors.black,
            ),
            actions: [
              WalletButton.primaryButton(
                buttonText: 'Cerrar.',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );

    showDialog(context: context, builder: (ctx) => dialogContent);
  }

  void _selectCategory(Category category, String? subId, String displayName) {
    if (!mounted) return;
    setState(() {
      _selectedCategory = category;
      _selectedSubcategoryId = subId;
      _categoryController.text = displayName;
    });
  }

  Widget _buildTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 8,
          child: CustomTextField(
            controller: _titleController,
            label: 'Título',
            maxLength: 50,
            hideCounter: true,
            flat: true,
          ),
        ),
      ],
    );
  }
}
