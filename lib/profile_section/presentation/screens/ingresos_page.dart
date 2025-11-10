import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/core/data_remote/firebase_Service.dart';
import 'package:app_wallet/core/data_base_local/local_crud.dart';
import 'package:intl/intl.dart';
import 'package:app_wallet/components_section/utils/text_formatters.dart';
import 'package:app_wallet/core/sync_service/sync_service.dart';

class IngresosPage extends StatefulWidget {
  const IngresosPage({Key? key}) : super(key: key);

  @override
  State<IngresosPage> createState() => _IngresosPageState();
}

class _IngresosPageState extends State<IngresosPage> {
  final TextEditingController _amountController = TextEditingController();
  int _months = 1;
  List<DateTime> _previewMonths = [];
  final NumberFormat _clpFormatter = NumberFormat.currency(locale: 'es_CL', symbol: '', decimalDigits: 0);
  // cache of local incomes by id (YYYYMM) -> row map
  Map<String, Map<String, dynamic>> _localIncomes = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLocalIncomes();
    _generatePreview();
  }

  Future<void> _loadLocalIncomes() async {
    try {
      final rows = await getIncomesLocalImpl();
      final map = <String, Map<String, dynamic>>{};
      for (final r in rows) {
        final id = r['id']?.toString() ?? '';
        if (id.isNotEmpty) map[id] = r;
      }
      setState(() {
        _localIncomes = map;
      });
    } catch (_) {}
  }

  void _generatePreview() {
    final now = DateTime.now();
  final months = _months;
    final List<DateTime> list = [];
    for (var i = 0; i < months; i++) {
      final d = DateTime(now.year, now.month + i, 1);
      list.add(d);
    }
    setState(() {
      _previewMonths = list;
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });
    int parseClp(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final amount = parseClp(_amountController.text);
  final months = _months;
    if (amount <= 0 || months <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese monto y meses válidos')));
      return;
    }

    final now = DateTime.now();
    final snack = ScaffoldMessenger.of(context);
    snack.showSnackBar(const SnackBar(content: Text('Guardando ingresos...')));

    for (var i = 0; i < months; i++) {
      final date = DateTime(now.year, now.month + i, 1);
      final id = '${date.year}${date.month.toString().padLeft(2, '0')}';
      try {
        // Try remote upsert first. If it succeeds, mark local as synced.
        await upsertIncomeEntry(date, amount, null, docId: id);
        await createIncomeLocalImpl(date, amount, null, id: id, syncStatus: SyncStatus.synced.index);
      } catch (_) {
        // If remote fails (offline), create local with pendingCreate status so SyncService will upload later.
        try {
          await createIncomeLocalImpl(date, amount, null, id: id, syncStatus: SyncStatus.pendingCreate.index);
        } catch (_) {}
      }
    }
    // Refresh local cache so preview shows the newly saved rows even when offline
    await _loadLocalIncomes();
    _generatePreview();
    setState(() {
      _isSaving = false;
    });
    snack.showSnackBar(const SnackBar(content: Text('Ingresos guardados')));
    // Close page and signal caller that we saved (so calling screen can refresh if needed)
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WalletAppBar(title: AwText.normal('Ingresos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AwText.bold('Ingresos mensuales', size: AwSize.s18),
            AwSpacing.s12,
                    AwText.normal('Monto por mes (CLP)', color: AwColors.grey),
            AwSpacing.s6,
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, CLPTextInputFormatter()],
                      decoration: const InputDecoration(hintText: 'p. ej. 700.000'),
                    ),
            AwSpacing.s12,
      AwText.normal('Número de meses (1-12)', color: AwColors.grey),
                    AwSpacing.s6,
                    DropdownButton<int>(
                      value: _months,
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _months = v;
                        });
                        _generatePreview();
                      },
                    ),
            AwSpacing.s12,
            Row(
              children: [
                ElevatedButton(onPressed: _generatePreview, child: const Text('Vista previa')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
                ),
              ],
            ),
            AwSpacing.s18,
            AwText.bold('Previsualización', size: AwSize.s16),
            AwSpacing.s6,
            Expanded(
              child: ListView.builder(
                itemCount: _previewMonths.length,
                itemBuilder: (context, idx) {
                  final d = _previewMonths[idx];
                  final fijo = (_amountController.text.isEmpty)
                      ? 0
                      : (int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0);
                  final id = '${d.year}${d.month.toString().padLeft(2, '0')}';
                  final existing = _localIncomes[id];
                  final imprevisto = existing != null ? (existing['ingreso_imprevisto'] as int? ?? 0) : 0;
                  final total = fijo + imprevisto;
                  return Card(
                    child: ListTile(
                      title: AwText.normal(idx == 0 ? 'Mes actual' : '${idx + 1} meses'),
                      subtitle: AwText.normal('Fijo: ${_clpFormatter.format(fijo)}  ·  Imprevisto: ${_clpFormatter.format(imprevisto)}'),
                      trailing: AwText.bold(_clpFormatter.format(total)),
                      onTap: () async {
                        // abrir diálogo para añadir/modificar imprevisto para este mes
                        final value = await showDialog<int>(
                            context: context,
                            builder: (ctx) {
                              final ctrl = TextEditingController();
                              return AlertDialog(
                                title: const Text('Gasto imprevisto del mes'),
                                content: TextField(
                                  controller: ctrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CLPTextInputFormatter()],
                                  decoration: const InputDecoration(hintText: 'p. ej. 50.000'),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                                  TextButton(
                                      onPressed: () {
                                        final val = int.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                        Navigator.of(ctx).pop(val);
                                      },
                                      child: const Text('Agregar')),
                                ],
                              );
                            });
                        if (value != null) {
                          // upsert both local and remote for this month
                          final monthDate = DateTime(d.year, d.month, 1);
                          final id = '${monthDate.year}${monthDate.month.toString().padLeft(2, '0')}';
                          final fijoToSave = fijo;
                          try {
                            await upsertIncomeEntry(monthDate, fijoToSave, value, docId: id);
                          } catch (_) {}
                          try {
                            await createIncomeLocalImpl(monthDate, fijoToSave, value, id: id, syncStatus: SyncStatus.pendingUpdate.index);
                          } catch (_) {}
                          // refresh local incomes cache and preview
                          await _loadLocalIncomes();
                          _generatePreview();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
