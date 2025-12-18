import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/core/providers/profile/ingresos_provider.dart';

class IngresosPreviewList extends StatelessWidget {
  final List<DateTime> previewMonths;
  final Map<String, dynamic> localIncomes;
  final int debouncedAmount;
  final NumberFormat clpFormatter;
  final IngresosNotifier ctrl;

  const IngresosPreviewList({
    Key? key,
    required this.previewMonths,
    required this.localIncomes,
    required this.debouncedAmount,
    required this.clpFormatter,
    required this.ctrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: previewMonths.map((d) {
        final id = '${d.year}${d.month.toString().padLeft(2, '0')}';
        final existing = localIncomes[id];
        final fijo = debouncedAmount > 0
            ? debouncedAmount
            : (existing != null ? (existing['ingreso_fijo'] as int? ?? 0) : 0);
        final imprevisto = debouncedAmount > 0
            ? 0
            : (existing != null
                ? (existing['ingreso_imprevisto'] as int? ?? 0)
                : 0);

        final existingFijo =
            existing != null ? (existing['ingreso_fijo'] as int? ?? 0) : 0;
        final existingImp = existing != null
            ? (existing['ingreso_imprevisto'] as int? ?? 0)
            : 0;
        String fijoTextStr;
        if (debouncedAmount > 0) {
          if (existingFijo > 0 && existingFijo != debouncedAmount) {
            fijoTextStr =
                '${clpFormatter.format(debouncedAmount)} (guardado: ${clpFormatter.format(existingFijo)})';
          } else {
            fijoTextStr = clpFormatter.format(debouncedAmount);
          }
        } else {
          fijoTextStr = clpFormatter.format(fijo);
        }

        String imprevistoTextStr;
        if (debouncedAmount > 0) {
          if (existingImp > 0) {
            imprevistoTextStr =
                '0 (guardado: ${clpFormatter.format(existingImp)})';
          } else {
            imprevistoTextStr = clpFormatter.format(0);
          }
        } else {
          imprevistoTextStr = clpFormatter.format(imprevisto);
        }

        final previewTotal = (debouncedAmount > 0 ? debouncedAmount : fijo) +
            (debouncedAmount > 0 ? 0 : imprevisto);
        final totalTextStr = clpFormatter.format(previewTotal);
        String monthLabelRaw =
            (d.year == DateTime.now().year && d.month == DateTime.now().month)
                ? 'Mes actual'
                : DateFormat('MMMM yyyy', 'es').format(d);

        final monthLabel = monthLabelRaw.isNotEmpty
            ? '${monthLabelRaw[0].toUpperCase()}${monthLabelRaw.substring(1)}'
            : monthLabelRaw;
        final monthDate = DateTime(d.year, d.month, 1);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: IncomePreviewTile(
            monthLabel: monthLabel,
            fijoText: fijoTextStr,
            imprevistoText: imprevistoTextStr,
            totalText: totalTextStr,
            onTap: () async {
              final saved = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => IngresosImprevistosPage(
                      initialMonth: monthDate, initialImprevisto: imprevisto),
                ),
              );
              if (saved == true) {
                await ctrl.loadLocalIncomes();
              }
            },
            onEdit: () async {
              final fmt = NumberFormat.currency(
                  locale: 'es_CL', symbol: '', decimalDigits: 0);
              final fijoCtrl = TextEditingController(text: fmt.format(fijo));
              final impCtrl =
                  TextEditingController(text: fmt.format(imprevisto));
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
                        AwSpacing.s6,
                        CustomTextField(
                            controller: fijoCtrl,
                            label: 'Ingreso mensual',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              MaxAmountFormatter(
                                  maxDigits: MaxAmountFormatter.kEightDigits,
                                  maxAmount:
                                      MaxAmountFormatter.kEightDigitsMaxAmount,
                                  onAttemptOverLimit: () {}),
                              CLPTextInputFormatter()
                            ]),
                        AwSpacing.s6,
                        CustomTextField(
                            controller: impCtrl,
                            label: 'Imprevisto (opcional)',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              MaxAmountFormatter(
                                  maxDigits: MaxAmountFormatter.kEightDigits,
                                  maxAmount:
                                      MaxAmountFormatter.kEightDigitsMaxAmount,
                                  onAttemptOverLimit: () {}),
                              CLPTextInputFormatter()
                            ]),
                        AwSpacing.s12,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancelar')),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AwColors.lightBlue),
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
                final newFijo = int.tryParse(
                        fijoCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                    0;
                final newImp = int.tryParse(
                        impCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                    0;
                await ctrl.updateIncomeForDate(monthDate, newFijo, newImp);
                await ctrl.loadLocalIncomes();

                try {
                  // ignore: use_build_context_synchronously
                  final controller = context.read<WalletExpensesController>();
                  controller.setMonthFilter(
                      DateTime(monthDate.year, monthDate.month));
                } catch (_) {}

                // ignore: use_build_context_synchronously
                final rootNav = Navigator.of(context, rootNavigator: true);
                await rootNav.pushNamedAndRemoveUntil(
                  '/home-page',
                  (r) => false,
                  arguments: {
                    'showPopup': true,
                    'title': 'Mes editado correctamente'
                  },
                );
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
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar')),
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Eliminar')),
                  ],
                ),
              );
              if (confirm == true) {
                final ok = await ctrl.deleteIncomeForDate(monthDate);
                if (ok) {
                  await ctrl.loadLocalIncomes();
                  try {
                    final controller = context.read<WalletExpensesController>();
                    controller.setMonthFilter(
                        DateTime(monthDate.year, monthDate.month));
                  } catch (_) {}

                  final rootNav = Navigator.of(context, rootNavigator: true);
                  await rootNav.pushNamedAndRemoveUntil(
                    '/home-page',
                    (r) => false,
                    arguments: {
                      'showPopup': true,
                      'title': 'Ingreso eliminado'
                    },
                  );
                } else {
                  // ignore: use_build_context_synchronously
                  WalletPopup.showNotificationWarningOrange(
                      // ignore: use_build_context_synchronously
                      context: context,
                      message: 'Error eliminando ingreso');
                }
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
