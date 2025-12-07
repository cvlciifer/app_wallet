import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/profile_section/presentation/screens/registro_ingresos_page.dart';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:app_wallet/core/providers/profile/ingresos_provider.dart';

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

class IngresosPage extends ConsumerStatefulWidget {
  const IngresosPage({Key? key}) : super(key: key);

  @override
  ConsumerState<IngresosPage> createState() => _IngresosPageState();
}

class _IngresosPageState extends ConsumerState<IngresosPage> {
  final TextEditingController _amountController = TextEditingController();
  final _clpFormatter = NumberFormat.currency(locale: 'es_CL', symbol: r'$', decimalDigits: 0);
  Timer? _maxErrorTimer;
  bool _showMaxError = false;
  bool _isAmountValid = false;
  Timer? _debounceTimer;
  int _debouncedAmount = 0;
  final GlobalKey _amountFieldKey = GlobalKey();
  final GlobalKey _monthSelectorKey = GlobalKey();
  final GlobalKey _monthsCountKey = GlobalKey();
  final GlobalKey _saveButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ingresosProvider.notifier).loadLocalIncomes();
      try {
        ref.read(ingresosProvider.notifier).setMonths(1);
      } catch (_) {}

      WidgetsBinding.instance.addPostFrameCallback((__) async {
        try {
          final args = ModalRoute.of(context)?.settings.arguments;
          final shouldRun = (args is Map && args['showFTUOnIngresos'] == true);
          if (shouldRun) {
            await Future.delayed(const Duration(milliseconds: 300));
            await _runIngresosOnboardingSequence();
          }
        } catch (_) {}
      });
    });
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _maxErrorTimer?.cancel();
    _debounceTimer?.cancel();
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _runIngresosOnboardingSequence() async {
    try {
      await _showOverlayForKey(
        _amountFieldKey,
        title: 'Ingresa tu monto mensual',
        message: 'Este monto es tu ingreso mensual y se verá reflejado en el home. Presiona Continuar para seguir.',
        continueText: 'Continuar',
      );

      await _showOverlayForKey(
        _monthSelectorKey,
        title: 'Selecciona el mes de inicio',
        message: 'Elige desde qué mes quieres aplicar este ingreso.',
        continueText: 'Continuar',
      );

      await _showOverlayForKey(
        _monthsCountKey,
        title: 'Cantidad de meses',
        message: 'Selecciona cuántos meses quieres actualizar.',
        continueText: 'Continuar',
      );

      await _showOverlayForKey(
        _saveButtonKey,
        title: 'Guardar ingreso',
        message: 'Presiona Guardar Ingreso para aplicar los cambios.',
        continueText: 'Continuar',
      );

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home-page',
          (r) => false,
          arguments: {'continueFTUAfterIngresosAdd': true},
        );
      }
    } catch (_) {}
  }

  Future<void> _showOverlayForKey(GlobalKey key,
      {required String title, required String message, String continueText = 'Continuar'}) async {
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

      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'ingresos_ftu',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, a1, a2) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Material(
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
                    left: targetPos.dx - 8,
                    top: targetPos.dy - 8,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: targetSize.width + 16,
                        height: targetSize.height + 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AwColors.appBarColor, width: 3),
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
                      const popupApproxH = 160.0;

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
                                  buttonText: continueText,
                                  onPressed: () {
                                    Navigator.of(context).pop();
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
            ),
          );
        },
      );
    } catch (_) {}
  }

  void _onAmountChanged() {
    final raw = _amountController.text;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final current = int.tryParse(digits) ?? 0;
    developer.log('[IngresosPage][_onAmountChanged] raw="$raw" digits="$digits" current=$current');
    final valid = digits.isNotEmpty && current <= MaxAmountFormatter.kEightDigitsMaxAmount;
    if (valid != _isAmountValid) {
      if (!mounted) return;
      setState(() {
        _isAmountValid = valid;
      });
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _debouncedAmount = current;
      });
      developer.log('[IngresosPage][_debouncedAmount] $_debouncedAmount');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ingresosProvider);
    final ctrl = ref.read(ingresosProvider.notifier);

    return Scaffold(
        backgroundColor: AwColors.white,
        appBar: const WalletAppBar(
          title: AwText.bold('Mi Wallet', color: AwColors.white),
          automaticallyImplyLeading: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: TicketCard(
                notchDepth: 12,
                elevation: 6,
                color: AwColors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: AwSize.s26,
                            color: AwColors.appBarColor,
                          ),
                          AwSpacing.w12,
                          Expanded(
                            child: AwText.bold(
                              'Ingreso Mensual',
                              size: AwSize.s20,
                              color: AwColors.appBarColor,
                            ),
                          ),
                        ],
                      ),
                      AwSpacing.s6,
                      const AwText.normal(
                        'Ingresa un Monto Mensual, selecciona el mes desde el que quieres comenzar y cuántos meses deseas modificar. Solo puedes editar meses dentro del rango de un año antes y un año después del mes actual.',
                        size: AwSize.s14,
                        color: AwColors.modalGrey,
                        maxLines: 4,
                      ),
                      //AwSpacing.s12,
                      AwSpacing.s6,
                      Container(
                        key: _amountFieldKey,
                        child: IngresosAmountField(
                          controller: _amountController,
                          showMaxError: _showMaxError,
                          onChanged: (_) => _onAmountChanged(),
                          onAttemptOverLimit: () {
                            if (!mounted) return;
                            setState(() {
                              _showMaxError = true;
                            });
                            _maxErrorTimer?.cancel();
                            _maxErrorTimer = Timer(const Duration(seconds: 2), () {
                              if (mounted) {
                                setState(() => _showMaxError = false);
                              }
                            });
                          },
                        ),
                      ),

                      AwSpacing.s12,
                      IngresosControls(
                        initialMonth: state.previewMonths.isNotEmpty
                            ? state.previewMonths.first
                            : DateTime(DateTime.now().year, DateTime.now().month + state.startOffset, 1),
                        startOffset: state.startOffset,
                        months: state.months,
                        ctrl: ctrl,
                        monthsCountKey: _monthsCountKey,
                        monthSelectorKey: _monthSelectorKey,
                        saveButtonKey: _saveButtonKey,
                        onSave: () async {
                          final fijo = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          if (fijo <= 0) return;

                          try {
                            ref.read(globalLoaderProvider.notifier).state = true;
                          } catch (_) {}

                          try {
                            final controller = context.read<WalletExpensesController>();
                            final rootNav = Navigator.of(context, rootNavigator: true);

                            for (final d in state.previewMonths) {
                              final monthDate = DateTime(d.year, d.month, 1);
                              await ctrl.updateIncomeForDate(monthDate, fijo, null);
                            }

                            if (state.previewMonths.isNotEmpty) {
                              final first = state.previewMonths.first;
                              try {
                                controller.setMonthFilter(DateTime(first.year, first.month));
                              } catch (_) {}
                            }

                            final conn = await Connectivity().checkConnectivity();
                            final hasConnection = conn != ConnectivityResult.none;

                            await rootNav.pushNamedAndRemoveUntil(
                              '/home-page',
                              (r) => false,
                              arguments: {
                                'showPopup': true,
                                'title': 'Ingreso guardado',
                                if (!hasConnection)
                                  'message': const AwText.normal(
                                    'Será sincronizado cuando exista internet',
                                    color: AwColors.white,
                                    size: AwSize.s14,
                                  ),
                              },
                            );

                            try {
                              ref.read(globalLoaderProvider.notifier).state = false;
                            } catch (_) {}
                          } catch (e) {
                            try {
                              ref.read(globalLoaderProvider.notifier).state = false;
                            } catch (_) {}
                            final popupCtx = Navigator.of(context, rootNavigator: true).overlay?.context ?? context;
                            try {
                              WalletPopup.showNotificationError(context: popupCtx, title: 'Error guardando ingreso');
                            } catch (_) {}
                          }
                        },
                        onOpenRegistro: () async {
                          await Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const RegistroIngresosPage()));
                          await ctrl.loadLocalIncomes();
                        },
                      ),
                      AwSpacing.s12,
                      if (state.previewMonths.isNotEmpty) ...[
                        const AwText.bold('Visualización De Ingreso Por Meses',
                            size: AwSize.s18, color: AwColors.appBarColor),
                        AwSpacing.s6,
                        IngresosPreviewList(
                            previewMonths: state.previewMonths,
                            localIncomes: state.localIncomes,
                            debouncedAmount: _debouncedAmount,
                            clpFormatter: _clpFormatter,
                            ctrl: ctrl),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
