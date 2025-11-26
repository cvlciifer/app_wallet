import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/components_section/widgets/profile/income_preview_tile.dart';
import 'package:app_wallet/profile_section/presentation/screens/registro_ingresos_page.dart';
import 'package:app_wallet/components_section/widgets/profile/month_selector.dart';
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
      NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
  Timer? _maxErrorTimer;
  bool _showMaxError = false;
  bool _isAmountValid = false;

  @override
  void initState() {
    super.initState();
    // load local incomes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ingresosProvider.notifier).loadLocalIncomes();
    });
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _maxErrorTimer?.cancel();
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final current = int.tryParse(digits) ?? 0;
    final valid = digits.isNotEmpty &&
        current <= MaxAmountFormatter.kEightDigitsMaxAmount;
    if (valid != _isAmountValid) {
      if (!mounted) return;
      setState(() {
        _isAmountValid = valid;
      });
    }
  }

  DateTime _addMonths(DateTime dt, int months) {
    final y = dt.year + ((dt.month - 1 + months) ~/ 12);
    final m = ((dt.month - 1 + months) % 12) + 1;
    final day = dt.day;
    final lastDayOfMonth = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, day <= lastDayOfMonth ? day : lastDayOfMonth);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ingresosProvider);
    final ctrl = ref.read(ingresosProvider.notifier);

    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold('Ingreso mensual', color: AwColors.white),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: TicketCard(
          notchDepth: 12,
          elevation: 6,
          color: AwColors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AwSpacing.s6,
                const AwText.normal(
                  'Selecciona el mes de inicio y la cantidad de meses que quieres editar. Los meses se actualizan en una ventana de -12 a +12 respecto al mes actual.',
                  size: AwSize.s14,
                  color: AwColors.modalGrey,
                ),
                AwSpacing.s18,
                const AwText.normal('Mes de inicio',
                    size: AwSize.s14, color: AwColors.grey),
                AwSpacing.s6,
                MonthSelector(
                  month: state.previewMonths.isNotEmpty
                      ? state.previewMonths.first
                      : _addMonths(DateTime.now(), state.startOffset),
                  canPrev: state.startOffset > -12,
                  canNext: state.startOffset < 12,
                  onPrev: () => ctrl.setStartOffset(state.startOffset - 1),
                  onNext: () => ctrl.setStartOffset(state.startOffset + 1),
                ),
                AwSpacing.s12,
                const AwText.normal('Cantidad de meses',
                    size: AwSize.s14, color: AwColors.grey),
                AwSpacing.s6,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Left arrow: show only when months > 1
                    if (state.months > 1)
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        color: AwColors.appBarColor,
                        onPressed: () => ctrl.setMonths(state.months - 1),
                      )
                    else
                      AwSpacing.w48,

                    AwText.bold(
                      state.months == 1 ? '1 mes' : '${state.months} meses',
                      size: AwSize.s16,
                      color: AwColors.appBarColor,
                    ),

                    // Right arrow: show only when months < 12
                    if (state.months < 12)
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: AwColors.appBarColor,
                        onPressed: () => ctrl.setMonths(state.months + 1),
                      )
                    else
                      AwSpacing.w48,
                  ],
                ),
                AwSpacing.m,
                const AwText.bold('Ingreso mensual', size: AwSize.s14),
                AwSpacing.s6,
                CustomTextField(
                  controller: _amountController,
                  label: 'Ingrese monto en CLP',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    MaxAmountFormatter(
                      maxDigits: MaxAmountFormatter.kEightDigits,
                      maxAmount: MaxAmountFormatter.kEightDigitsMaxAmount,
                      onAttemptOverLimit: () {
                        if (!mounted) return;
                        setState(() {
                          _showMaxError = true;
                        });
                        _maxErrorTimer?.cancel();
                        _maxErrorTimer = Timer(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _showMaxError = false);
                        });
                      },
                    ),
                    CLPTextInputFormatter(),
                  ],
                  textSize: 16,
                ),
                if (_showMaxError)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: AwText.normal('Tope máximo: 8 dígitos (99.999.999)',
                        color: AwColors.red, size: AwSize.s14),
                  ),
                AwSpacing.s12,
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAmountValid
                            ? () async {
                                final fijo = int.tryParse(_amountController.text
                                        .replaceAll(RegExp(r'[^0-9]'), '')) ??
                                    0;
                                if (fijo <= 0) return;
                                for (final d in state.previewMonths) {
                                  final monthDate =
                                      DateTime(d.year, d.month, 1);
                                  await ctrl.updateIncomeForDate(
                                      monthDate, fijo, null);
                                }
                                WalletPopup.showNotificationSuccess(
                                  context: context,
                                  title: 'Ingreso guardado',
                                );
                                await ctrl.loadLocalIncomes();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AwColors.blueGrey,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AwSize.s12)),
                        ),
                        child: const AwText.bold('Guardar Ingreso',
                            color: AwColors.white),
                      ),
                    ),
                  ],
                ),
                AwSpacing.s12,
                SizedBox(
                  height: AwSize.s48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const RegistroIngresosPage()));
                      await ctrl.loadLocalIncomes();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AwColors.appBarColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AwSize.s16)),
                    ),
                    child: const Center(
                      child: AwText.bold('Registro de ingresos',
                          color: AwColors.white),
                    ),
                  ),
                ),
                AwSpacing.s20,
                const AwText.bold('Ingresos por meses',
                    size: AwSize.s18, color: AwColors.appBarColor),
                AwSpacing.s6,
                Column(
                  children: state.previewMonths.map((d) {
                    final id = '${d.year}${d.month.toString().padLeft(2, '0')}';
                    final existing = state.localIncomes[id];
                    final fijo = existing != null
                        ? (existing['ingreso_fijo'] as int? ?? 0)
                        : 0;
                    final imprevisto = existing != null
                        ? (existing['ingreso_imprevisto'] as int? ?? 0)
                        : 0;
                    final total = fijo + imprevisto;
                    String monthLabelRaw = (d.year == DateTime.now().year &&
                            d.month == DateTime.now().month)
                        ? 'Mes actual'
                        : DateFormat('MMMM yyyy', 'es').format(d);
                    // Capitalize first letter of month label
                    final monthLabel = monthLabelRaw.isNotEmpty
                        ? '${monthLabelRaw[0].toUpperCase()}${monthLabelRaw.substring(1)}'
                        : monthLabelRaw;
                    final monthDate = DateTime(d.year, d.month, 1);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: IncomePreviewTile(
                        monthLabel: monthLabel,
                        fijoText: _clpFormatter.format(fijo),
                        imprevistoText: _clpFormatter.format(imprevisto),
                        totalText: _clpFormatter.format(total),
                        onTap: () async {
                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => IngresosImprevistosPage(
                                  initialMonth: monthDate,
                                  initialImprevisto: imprevisto),
                            ),
                          );
                          if (saved == true) await ctrl.loadLocalIncomes();
                        },
                        onEdit: () async {
                          final fmt = NumberFormat.currency(
                              locale: 'es_CL', symbol: '', decimalDigits: 0);
                          final fijoCtrl =
                              TextEditingController(text: fmt.format(fijo));
                          final impCtrl = TextEditingController(
                              text: fmt.format(imprevisto));
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => Dialog(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const AwText.bold('Editar ingreso del mes',
                                        size: AwSize.s16),
                                    AwSpacing.s,
                                    CustomTextField(
                                        controller: fijoCtrl,
                                        label: 'Ingreso mensual',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          MaxAmountFormatter(
                                              maxDigits: MaxAmountFormatter
                                                  .kEightDigits,
                                              maxAmount: MaxAmountFormatter
                                                  .kEightDigitsMaxAmount,
                                              onAttemptOverLimit: () {
                                                if (mounted) {
                                                  /* ignore UI here */
                                                }
                                              }),
                                          CLPTextInputFormatter()
                                        ]),
                                    AwSpacing.s6,
                                    CustomTextField(
                                        controller: impCtrl,
                                        label: 'Imprevisto (opcional)',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          MaxAmountFormatter(
                                              maxDigits: MaxAmountFormatter
                                                  .kEightDigits,
                                              maxAmount: MaxAmountFormatter
                                                  .kEightDigitsMaxAmount,
                                              onAttemptOverLimit: () {
                                                if (mounted) {
                                                  /* ignore UI here */
                                                }
                                              }),
                                          CLPTextInputFormatter()
                                        ]),
                                    AwSpacing.s12,
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('Cancelar')),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AwColors.lightBlue),
                                          child: const Text('Guardar'),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                          if (ok == true) {
                            final newFijo = int.tryParse(fijoCtrl.text
                                    .replaceAll(RegExp(r'[^0-9]'), '')) ??
                                0;
                            final newImp = int.tryParse(impCtrl.text
                                    .replaceAll(RegExp(r'[^0-9]'), '')) ??
                                0;
                            await ctrl.updateIncomeForDate(monthDate, newFijo,
                                newImp == 0 ? null : newImp);
                            await ctrl.loadLocalIncomes();
                          }
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const AwText.bold('Eliminar ingreso'),
                              content: AwText.normal(
                                  '¿Eliminar ingreso fijo y imprevisto de ${DateFormat('MMMM yyyy', 'es').format(monthDate)}?',
                                  size: AwSize.s14,
                                  color: AwColors.modalGrey),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Eliminar')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final ok =
                                await ctrl.deleteIncomeForDate(monthDate);
                            if (ok) {
                              WalletPopup.showNotificationSuccess(
                                context: context,
                                title: 'Ingreso eliminado',
                              );
                              await ctrl.loadLocalIncomes();
                            } else {
                              WalletPopup.showNotificationWarningOrange(
                                context: context,
                                message: 'Error eliminando ingreso',
                              );
                            }
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
