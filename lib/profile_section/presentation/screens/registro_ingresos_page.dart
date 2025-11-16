import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/components_section/widgets/profile/income_preview_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/core/providers/profile/ingresos_provider.dart';
import 'package:intl/intl.dart';

class RegistroIngresosPage extends ConsumerWidget {
  const RegistroIngresosPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ingresosProvider);
    final ctrl = ref.read(ingresosProvider.notifier);
    final formatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    // Build a sorted list of incomes from localIncomes map
    final entriesAll = state.localIncomes.values.toList();
    // Filter to only months that have any ingreso (fijo>0 or imprevisto>0)
    final entries = entriesAll.where((row) {
      final fijo = (row['ingreso_fijo'] as int?) ?? 0;
      final imp = (row['ingreso_imprevisto'] as int?) ?? 0;
      return fijo > 0 || imp > 0;
    }).toList();
    entries.sort((a, b) {
      final fa = (a['fecha'] as int?) ?? 0;
      final fb = (b['fecha'] as int?) ?? 0;
      return fb.compareTo(fa);
    });

    return Scaffold(
      appBar: WalletAppBar(
        title: AwText.bold('Registro de ingresos', color: AwColors.white),
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
                if (entries.isEmpty)
                  AwText.normal('No hay ingresos registrados aún.', size: AwSize.s14, color: AwColors.modalGrey),
                ...entries.map((row) {
                  final fechaMs = (row['fecha'] as int?) ?? DateTime.now().millisecondsSinceEpoch;
                  final dt = DateTime.fromMillisecondsSinceEpoch(fechaMs);
                  final monthLabelRaw = DateFormat('MMMM yyyy', 'es').format(dt);
                  final monthLabel = monthLabelRaw.isNotEmpty ? '${monthLabelRaw[0].toUpperCase()}${monthLabelRaw.substring(1)}' : monthLabelRaw;
                  final fijo = (row['ingreso_fijo'] as int?) ?? 0;
                  final imprevisto = (row['ingreso_imprevisto'] as int?) ?? 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: IncomePreviewTile(
                      monthLabel: monthLabel,
                      fijoText: formatter.format(fijo),
                      imprevistoText: formatter.format(imprevisto),
                      totalText: formatter.format(fijo + imprevisto),
                      onEdit: () async {
                        final fmt = NumberFormat.currency(locale: 'es_CL', symbol: '', decimalDigits: 0);
                        final fijoCtrl = TextEditingController(text: fmt.format(fijo));
                        final impCtrl = TextEditingController(text: fmt.format(imprevisto));
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => Dialog(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const AwText.bold('Editar ingreso', size: AwSize.s16),
                                  const SizedBox(height: 8),
                                  CustomTextField(controller: fijoCtrl, label: 'Ingreso mensual', keyboardType: TextInputType.number, inputFormatters: [MaxAmountFormatter(maxDigits: MaxAmountFormatter.kEightDigits, maxAmount: MaxAmountFormatter.kEightDigitsMaxAmount), CLPTextInputFormatter()]),
                                  AwSpacing.s6,
                                  CustomTextField(controller: impCtrl, label: 'Imprevisto (opcional)', keyboardType: TextInputType.number, inputFormatters: [MaxAmountFormatter(maxDigits: MaxAmountFormatter.kEightDigits, maxAmount: MaxAmountFormatter.kEightDigitsMaxAmount), CLPTextInputFormatter()]),
                                  AwSpacing.s12,
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          style: ElevatedButton.styleFrom(backgroundColor: AwColors.lightBlue),
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
                          final newFijo = int.tryParse(fijoCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          final newImp = int.tryParse(impCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          final date = DateTime(dt.year, dt.month, 1);
                          await ctrl.updateIncomeForDate(date, newFijo, newImp == 0 ? null : newImp);
                          await ctrl.loadLocalIncomes();
                        }
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                          title: const AwText.bold('Eliminar ingreso'),
                          content: AwText.normal('¿Eliminar ingreso de ${DateFormat('MMMM yyyy', 'es').format(dt)}?', size: AwSize.s14, color: AwColors.modalGrey),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
                          ],
                        ));
                        if (confirm == true) {
                          final date = DateTime(dt.year, dt.month, 1);
                          final ok = await ctrl.deleteIncomeForDate(date);
                          if (ok) await ctrl.loadLocalIncomes();
                        }
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
