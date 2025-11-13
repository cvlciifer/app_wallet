import 'dart:async';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/core/models/recurring_expense.dart';
import 'package:app_wallet/core/providers/profile/recurrent_registry_provider.dart';
import 'package:provider/provider.dart' as prov;

class RecurrentRegistryPage extends ConsumerStatefulWidget {
  const RecurrentRegistryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RecurrentRegistryPage> createState() =>
      _RecurrentRegistryPageState();
}

class _RecurrentRegistryPageState extends ConsumerState<RecurrentRegistryPage> {
  WalletExpensesController? _controller;
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller =
          prov.Provider.of<WalletExpensesController>(context, listen: false);
      _controller?.addListener(_onControllerChanged);
      ref.read(recurrentRegistryProvider.notifier).loadRecurrents();
    });
  }

  void _onControllerChanged() {
    if ((_reloadTimer?.isActive ?? false)) return;
    _reloadTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(recurrentRegistryProvider.notifier).loadRecurrents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recurrentRegistryProvider);
    return Scaffold(
      appBar: WalletAppBar(
        title: ' ',
        showBackArrow: false,
        barColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AwColors.appBarColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: TicketCard(
                notchDepth: 12,
                elevation: 8,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    const AwText.bold('Registro de gastos recurrentes',
                        size: AwSize.s18, color: AwColors.appBarColor),
                    AwSpacing.s6,
                    const AwText.normal(
                        'Aquí verás tus recurrencias y podrás editar montos o eliminar desde un mes en adelante.',
                        size: AwSize.s14,
                        color: AwColors.modalGrey),
                    const SizedBox(height: 12),
                    const Divider(),
                    if (state.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: AwText.normal('No hay gastos recurrentes aún.',
                            color: AwColors.modalGrey),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (ctx, i) {
                          final r = state.items[i];
                          return ListTile(
                            title:
                                AwText.bold(r.title, color: AwColors.boldBlack),
                            subtitle: AwText(
                                text:
                                    'Monto: ${r.amount.toInt()} • ${r.months} meses • Día ${r.dayOfMonth}'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () async {
                              final res = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          RecurrentDetailPage(recurring: r)));
                              if (res == true)
                                await ref
                                    .read(recurrentRegistryProvider.notifier)
                                    .loadRecurrents();
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
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
class RecurrentDetailPage extends ConsumerStatefulWidget {
  final RecurringExpense recurring;
  const RecurrentDetailPage({Key? key, required this.recurring})
      : super(key: key);

  @override
  ConsumerState<RecurrentDetailPage> createState() =>
      _RecurrentDetailPageState();
}

class _RecurrentDetailPageState extends ConsumerState<RecurrentDetailPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  WalletExpensesController? _controller;
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller =
          prov.Provider.of<WalletExpensesController>(context, listen: false);
      _controller?.addListener(_onControllerChanged);
      _loadItems();
    });
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
      final rows = await ref
          .read(recurrentRegistryProvider.notifier)
          .getRecurringItems(widget.recurring.id);
      if (!mounted) return;
      setState(() => _items = rows);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _editAmount(int idx, Map<String, dynamic> row) async {
    final current = row['cantidad'] as int;
    final tc = TextEditingController(text: current.toString());
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: TicketCard(
          roundTopCorners: true,
          topCornerRadius: 10,
          compactNotches: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AwText.bold('Editar monto',
                  color: AwColors.blue, size: AwSize.s16),
              const SizedBox(height: 8),
              CustomTextField(
                controller: tc,
                keyboardType: TextInputType.number,
                label: 'Monto',
              ),
              const SizedBox(height: 12),
              // Centered primary save button
              WalletButton.primaryButton(
                buttonText: 'Guardar',
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: 8),
              // Cancel as an underlined text button centered
              WalletButton.textButton(
                buttonText: 'Cancelar',
                onPressed: () => Navigator.of(ctx).pop(false),
                alignment: MainAxisAlignment.center,
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      final newAmt = double.tryParse(tc.text) ?? current.toDouble();
      await ref
          .read(recurrentRegistryProvider.notifier)
          .updateRecurringItemAmount(
              widget.recurring.id, row['month_index'] as int, newAmt);
      // refresh global state
      try {
        final controller =
            prov.Provider.of<WalletExpensesController>(context, listen: false);
        await controller.loadExpensesSmart();
      } catch (_) {}
      await _loadItems();
    }
  }

  Future<void> _deleteFromThisMonth(int monthIndex) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const AwText.bold('Eliminar desde este mes'),
            content: const AwText(
                text:
                    'Se eliminarán los gastos de este mes y siguientes de la recurrencia. Esta acción no afecta meses anteriores.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Eliminar')),
            ],
          );
        });
    if (ok == true) {
      // Do a fast, local-first deletion that removes mapping rows and marks
      // affected expenses as pendingDelete in a single transaction. This is
      // much faster than deleting each expense remotely/synchronously and
      // keeps the UI snappy. The background sync will attempt remote deletes.
      final success = await ref
          .read(recurrentRegistryProvider.notifier)
          .deleteRecurrenceFromMonth(widget.recurring.id, monthIndex);
      if (success) {
        try {
          final controller = prov.Provider.of<WalletExpensesController>(context,
              listen: false);
          await controller.loadExpensesSmart();
        } catch (_) {}
      }

      await _loadItems();
      // refresh parent
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WalletAppBar(
        title: ' ',
        showBackArrow: false,
        barColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AwColors.appBarColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: TicketCard(
                notchDepth: 12,
                elevation: 8,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    AwText.bold(widget.recurring.title,
                        size: AwSize.s18, color: AwColors.appBarColor),
                    AwSpacing.s6,
                    AwText.normal(
                        'Día del mes: ${widget.recurring.dayOfMonth} • ${widget.recurring.months} meses',
                        size: AwSize.s14,
                        color: AwColors.modalGrey),
                    const SizedBox(height: 12),
                    const Divider(),
                    if (_items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: AwText.normal(
                            'No hay items para esta recurrencia.',
                            color: AwColors.modalGrey),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (ctx, i) {
                          final r = _items[i];
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                              r['fecha'] as int);
                          return ListTile(
                            title: AwText.bold(
                                '${dt.year}-${dt.month.toString().padLeft(2, '0')}',
                                color: AwColors.boldBlack),
                            subtitle: AwText(text: 'Monto: ${r['cantidad']}'),
                            onTap: () => _showActionsForItem(r),
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
    );
  }

  void _showActionsForItem(Map<String, dynamic> row) async {
    final idx = row['month_index'] as int;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TicketCard(
              roundTopCorners: true,
              topCornerRadius: 12,
              compactNotches: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading:
                        const Icon(Icons.edit, color: AwColors.appBarColor),
                    title: const AwText.bold('Editar desde este mes'),
                    onTap: () => Navigator.of(ctx).pop('edit'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.redAccent),
                    title: const AwText.bold('Borrar desde este mes'),
                    onTap: () => Navigator.of(ctx).pop('delete'),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  // Centered Cancel underlined
                  WalletButton.textButton(
                    buttonText: 'Cancelar',
                    onPressed: () => Navigator.of(ctx).pop(null),
                    alignment: MainAxisAlignment.center,
                    colorText: AwColors.blue,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (choice == 'edit') {
      await _editAmount(idx, row);
      // reload both registry and global expenses
      try {
        final controller =
            prov.Provider.of<WalletExpensesController>(context, listen: false);
        await controller.loadExpensesSmart();
      } catch (_) {}
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
