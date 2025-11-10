import 'dart:developer';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/core/data_remote/firebase_Service.dart';
import 'package:app_wallet/core/data_base_local/local_crud.dart';
import 'package:app_wallet/components_section/utils/text_formatters.dart';
import 'package:app_wallet/core/sync_service/sync_service.dart';

class GastosImprevistosPage extends StatefulWidget {
  const GastosImprevistosPage({Key? key}) : super(key: key);

  @override
  State<GastosImprevistosPage> createState() => _GastosImprevistosPageState();
}

class _GastosImprevistosPageState extends State<GastosImprevistosPage> {
  final TextEditingController _amountCtrl = TextEditingController();
  int _selectedMonthOffset = 0; // 0 -> current month, 1 -> next, etc.
  // NumberFormat kept if needed later

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
  final value = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un valor válido')));
      return;
    }

    final now = DateTime.now();
    final target = DateTime(now.year, now.month + _selectedMonthOffset, 1);

      bool saved = false;
      try {
        // Preserve existing fijo if any
        final local = await getIncomesLocalImpl();
        final match = local.firstWhere((r) => r['fecha'] == target.millisecondsSinceEpoch, orElse: () => {});
        int fijo = 0;
        if (match.isNotEmpty) fijo = (match['ingreso_fijo'] as int?) ?? 0;

        final id = '${target.year}${target.month.toString().padLeft(2, '0')}';
        try {
          await upsertIncomeEntry(target, fijo, value, docId: id);
          await createIncomeLocalImpl(target, fijo, value, id: id, syncStatus: SyncStatus.synced.index);
        } catch (_) {
          await createIncomeLocalImpl(target, fijo, value, id: id, syncStatus: SyncStatus.pendingCreate.index);
        }

        saved = true;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingreso imprevisto guardado')));
      } catch (e) {
        log('gastos_imprevistos._save error: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error guardando imprevisto')));
      } finally {
        // Always pop and signal caller to refresh local state if we saved something.
        Navigator.of(context).pop(saved);
      }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = DateTime(now.year, now.month + _selectedMonthOffset, 1);
    return Scaffold(
      appBar: const WalletAppBar(title: AwText.normal('Gastos imprevistos del mes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AwText.normal('Mes seleccionado', color: AwColors.grey),
            AwSpacing.s6,
            Row(
              children: [
                Expanded(child: AwText.bold('${monthLabel.year} - ${monthLabel.month.toString().padLeft(2, '0')}', size: AwSize.s16)),
                IconButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedMonthOffset > 0) _selectedMonthOffset--;
                      });
                    },
                    icon: const Icon(Icons.chevron_left)),
                IconButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedMonthOffset < 11) _selectedMonthOffset++;
                      });
                    },
                    icon: const Icon(Icons.chevron_right)),
              ],
            ),
            AwSpacing.s12,
            AwText.normal('Valor imprevisto (CLP)', color: AwColors.grey),
            AwSpacing.s6,
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CLPTextInputFormatter()],
              decoration: const InputDecoration(hintText: 'p. ej. 50.000'),
            ),
            AwSpacing.s18,
            ElevatedButton(onPressed: _save, child: const Text('Agregar')),
          ],
        ),
      ),
    );
  }
}
