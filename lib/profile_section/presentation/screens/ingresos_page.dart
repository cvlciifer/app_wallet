import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/profile_section/presentation/screens/registro_ingresos_page.dart';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/core/providers/profile/ingresos_provider.dart';

class IngresosPage extends ConsumerStatefulWidget {
  const IngresosPage({Key? key}) : super(key: key);

  @override
  ConsumerState<IngresosPage> createState() => _IngresosPageState();
}

class _IngresosPageState extends ConsumerState<IngresosPage> {
  final TextEditingController _amountController = TextEditingController();
  final _clpFormatter =
      NumberFormat.currency(locale: 'es_CL', symbol: r'$', decimalDigits: 0);
  Timer? _maxErrorTimer;
  bool _showMaxError = false;
  bool _isAmountValid = false;
  Timer? _debounceTimer;
  int _debouncedAmount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ingresosProvider.notifier).loadLocalIncomes();
      try {
        // Default to 1 month instead of the 'Selecciona' placeholder.
        // This removes the 'Selecciona' option and shows '1 mes' by default.
        ref.read(ingresosProvider.notifier).setMonths(1);
      } catch (_) {}
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

  void _onAmountChanged() {
    final raw = _amountController.text;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final current = int.tryParse(digits) ?? 0;
    developer.log(
        '[IngresosPage][_onAmountChanged] raw="$raw" digits="$digits" current=$current');
    final valid = digits.isNotEmpty &&
        current <= MaxAmountFormatter.kEightDigitsMaxAmount;
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
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
                        'Selecciona el mes desde el que quieres comenzar y cuántos meses deseas modificar. Solo puedes editar meses dentro del rango de un año antes y un año después del mes actual.',
                        size: AwSize.s14,
                        color: AwColors.modalGrey,
                        maxLines: 4,
                      ),
                      //AwSpacing.s12,
                      AwSpacing.s6,
                      IngresosAmountField(
                        controller: _amountController,
                        showMaxError: _showMaxError,
                        onChanged: (_) => _onAmountChanged(),
                        onAttemptOverLimit: () {
                          if (!mounted) return;
                          setState(() {
                            _showMaxError = true;
                          });
                          _maxErrorTimer?.cancel();
                          _maxErrorTimer =
                              Timer(const Duration(seconds: 2), () {
                            if (mounted) {
                              setState(() => _showMaxError = false);
                            }
                          });
                        },
                      ),

                      AwSpacing.s12,
                      IngresosControls(
                        initialMonth: state.previewMonths.isNotEmpty
                            ? state.previewMonths.first
                            // If there are no preview months selected, use
                            // the provider's `startOffset` relative to now.
                            // This lets the MonthSelector update when the
                            // user taps the prev/next arrows even if
                            // `months == 0` (showing 'Selecciona').
                            : DateTime(DateTime.now().year,
                                DateTime.now().month + state.startOffset, 1),
                        startOffset: state.startOffset,
                        months: state.months,
                        ctrl: ctrl,
                        onSave: () async {
                          final fijo = int.tryParse(_amountController.text
                                  .replaceAll(RegExp(r'[^0-9]'), '')) ??
                              0;
                          if (fijo <= 0) return;

                          try {
                            ref.read(globalLoaderProvider.notifier).state =
                                true;
                          } catch (_) {}

                          try {
                            final controller =
                                context.read<WalletExpensesController>();
                            final rootNav =
                                Navigator.of(context, rootNavigator: true);

                            for (final d in state.previewMonths) {
                              final monthDate = DateTime(d.year, d.month, 1);
                              await ctrl.updateIncomeForDate(
                                  monthDate, fijo, null);
                            }

                            if (state.previewMonths.isNotEmpty) {
                              final first = state.previewMonths.first;
                              try {
                                controller.setMonthFilter(
                                    DateTime(first.year, first.month));
                              } catch (_) {}
                            }

                            final conn =
                                await Connectivity().checkConnectivity();
                            final hasConnection =
                                conn != ConnectivityResult.none;

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
                              ref.read(globalLoaderProvider.notifier).state =
                                  false;
                            } catch (_) {}
                          } catch (e) {
                            try {
                              ref.read(globalLoaderProvider.notifier).state =
                                  false;
                            } catch (_) {}
                            final popupCtx =
                                Navigator.of(context, rootNavigator: true)
                                        .overlay
                                        ?.context ??
                                    context;
                            try {
                              WalletPopup.showNotificationError(
                                  context: popupCtx,
                                  title: 'Error guardando ingreso');
                            } catch (_) {}
                          }
                        },
                        onOpenRegistro: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const RegistroIngresosPage()));
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
