import 'dart:async';

import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/core/models/recurring_expense.dart';

class RecurrentRegistryPage extends StatefulWidget {
  const RecurrentRegistryPage({Key? key}) : super(key: key);

  @override
  State<RecurrentRegistryPage> createState() => _RecurrentRegistryPageState();
}

class _RecurrentRegistryPageState extends State<RecurrentRegistryPage> {
  List<RecurringExpense> _items = [];
  bool _loading = true;
  WalletExpensesController? _controller;
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<WalletExpensesController>(context, listen: false);
    // Listen for global changes so registry updates when expenses are modified elsewhere
    _controller?.addListener(_onControllerChanged);
    _load();
  }

  void _onControllerChanged() {
    // Debounce reloads coming from global controller changes to avoid rapid
    // repeated DB reads / rebuilds that can freeze the UI.
    if ((_reloadTimer?.isActive ?? false)) return;
    _reloadTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final controller = Provider.of<WalletExpensesController>(context, listen: false);
      final list = await controller.syncService.localCrud.getRecurrents();
      if (!mounted) return;
      setState(() => _items = list);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WalletAppBar(title: AwText.bold('Registro de gastos recurrentes', color: AwColors.white), showBackArrow: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final r = _items[i];
                return TicketCard(
                  child: ListTile(
                    title: AwText.bold(r.title, color: AwColors.boldBlack),
                    subtitle: AwText(text: 'Monto: ${r.amount.toInt()} • ${r.months} meses • Día ${r.dayOfMonth}'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecurrentDetailPage(recurring: r)));
                      if (res == true) _load();
                    },
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _reloadTimer?.cancel();
    super.dispose();
  }
}

// Detail page
class RecurrentDetailPage extends StatefulWidget {
  final RecurringExpense recurring;
  const RecurrentDetailPage({Key? key, required this.recurring}) : super(key: key);

  @override
  State<RecurrentDetailPage> createState() => _RecurrentDetailPageState();
}

class _RecurrentDetailPageState extends State<RecurrentDetailPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  WalletExpensesController? _controller;
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<WalletExpensesController>(context, listen: false);
    _controller?.addListener(_onControllerChanged);
    _loadItems();
  }

  void _onControllerChanged() {
    // Debounce reloads to avoid frequent immediate DB calls
    if ((_reloadTimer?.isActive ?? false)) return;
    _reloadTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _loadItems();
    });
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final controller = Provider.of<WalletExpensesController>(context, listen: false);
      final rows = await controller.syncService.localCrud.getRecurringItems(widget.recurring.id);
      if (!mounted) return;
      setState(() => _items = rows);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _editAmount(int idx, Map<String, dynamic> row) async {
    final controller = Provider.of<WalletExpensesController>(context, listen: false);
    final current = row['cantidad'] as int;
    final tc = TextEditingController(text: current.toString());
    final ok = await showDialog<bool>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const AwText.bold('Editar monto'),
        content: CustomTextField(controller: tc, keyboardType: TextInputType.number, label: 'Monto'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Guardar')),
        ],
      );
    });
    if (ok == true) {
      final newAmt = double.tryParse(tc.text) ?? current.toDouble();
      await controller.syncService.localCrud.updateRecurringItemAmount(widget.recurring.id, row['month_index'] as int, newAmt);
      await _loadItems();
    }
  }

  Future<void> _deleteFromThisMonth(int monthIndex) async {
    final controller = Provider.of<WalletExpensesController>(context, listen: false);
    final ok = await showDialog<bool>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const AwText.bold('Eliminar desde este mes'),
        content: const AwText(text: 'Se eliminarán los gastos de este mes y siguientes de la recurrencia. Esta acción no afecta meses anteriores.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
        ],
      );
    });
    if (ok == true) {
  // Do a fast, local-first deletion that removes mapping rows and marks
  // affected expenses as pendingDelete in a single transaction. This is
  // much faster than deleting each expense remotely/synchronously and
  // keeps the UI snappy. The background sync will attempt remote deletes.
  await controller.syncService.localCrud.deleteRecurrenceFromMonth(widget.recurring.id, monthIndex);

      // Trigger a refresh of global expenses so UI updates immediately.
      await controller.loadExpensesSmart();

      await _loadItems();
      // refresh parent
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WalletAppBar(title: AwText.bold(widget.recurring.title, color: AwColors.white), showBackArrow: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final r = _items[i];
                final dt = DateTime.fromMillisecondsSinceEpoch(r['fecha'] as int);
                return TicketCard(
                  child: ListTile(
                    title: AwText.bold('${dt.year}-${dt.month.toString().padLeft(2, '0')}', color: AwColors.boldBlack),
                    subtitle: AwText(text: 'Monto: ${r['cantidad']}'),
                    onTap: () => _showActionsForItem(r),
                  ),
                );
              },
            ),
    );
  }

  void _showActionsForItem(Map<String, dynamic> row) async {
    final idx = row['month_index'] as int;
    final choice = await showModalBottomSheet<String>(context: context, builder: (ctx) {
      return SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.edit), title: const Text('Editar desde este mes'), onTap: () => Navigator.of(ctx).pop('edit')),
          ListTile(leading: const Icon(Icons.delete), title: const Text('Borrar desde este mes'), onTap: () => Navigator.of(ctx).pop('delete')),
          ListTile(leading: const Icon(Icons.close), title: const Text('Cancelar'), onTap: () => Navigator.of(ctx).pop(null)),
        ]),
      );
    });

    if (choice == 'edit') {
      await _editAmount(idx, row);
      // reload both registry and global expenses
      final controller = Provider.of<WalletExpensesController>(context, listen: false);
      await controller.loadExpensesSmart();
      await _loadItems();
    } else if (choice == 'delete') {
      await _deleteFromThisMonth(idx);
      // _deleteFromThisMonth already refreshes global state
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _reloadTimer?.cancel();
    super.dispose();
  }
}
