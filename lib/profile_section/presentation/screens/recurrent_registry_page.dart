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
      appBar: const WalletAppBar(
        title: AwText.bold(
          'Registros',
          color: AwColors.white,
        ),
        showBackArrow: false,
        barColor: AwColors.appBarColor,
        automaticallyImplyLeading: true,
        actions: const [],
      ),
      body: state.isLoading
          ? const Center(
              child: WalletLoader(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: TicketCard(
                compactNotches: true,
                roundTopCorners: true,
                notchDepth: 12,
                elevation: 8,
                color: AwColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AwSpacing.s12,
                    const AwText.bold(
                      'Registro de gastos recurrentes',
                      size: AwSize.s18,
                      color: AwColors.white,
                    ),
                    AwSpacing.s6,
                    const AwText.normal(
                        'Aquí verás tus recurrencias y podrás editar montos o eliminar desde un mes en adelante.',
                        size: AwSize.s14,
                        color: AwColors.modalGrey),
                    AwSpacing.s12,
                    const AwDivider(),
                    RecurrentList(
                      items: state.items,
                      onTapItem: (r) async {
                        final res = await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  RecurrentDetailPage(recurring: r)),
                        );
                        if (!mounted) return;
                        if (res == true) {
                          try {
                            ref.read(globalLoaderProvider.notifier).state =
                                true;
                          } catch (_) {}
                          try {
                            await ref
                                .read(recurrentRegistryProvider.notifier)
                                .loadRecurrents();
                          } catch (_) {}
                          try {
                            if (_controller != null) {
                              await _controller!.loadExpensesSmart();
                            } else {
                              final controller = prov.Provider.of<WalletExpensesController>(
                                  context,
                                  listen: false);
                              await controller.loadExpensesSmart();
                            }
                          } catch (_) {}
                          if (!mounted) return;
                          try {
                            ref.read(globalLoaderProvider.notifier).state =
                                false;
                          } catch (_) {}
                        }
                      },
                    ),
                    AwSpacing.s12,
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
      // ignore: deprecated_member_use
      barrierColor: AwColors.black.withOpacity(0.45),
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
              AwSpacing.s12,
              // Centered primary save button
              WalletButton.primaryButton(
                buttonText: 'Guardar',
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              AwSpacing.s,
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
            // ignore: use_build_context_synchronously
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
      if (monthIndex == 0) {
        try {
          ref.read(globalLoaderProvider.notifier).state = true;
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 100));
        final success = await ref
            .read(recurrentRegistryProvider.notifier)
            .deleteRecurrenceFromMonth(widget.recurring.id, monthIndex);
        if (success) {
          try {
            if (_controller != null) {
              await _controller!.loadExpensesSmart();
            } else {
              final controller = prov.Provider.of<WalletExpensesController>(
                  context,
                  listen: false);
              await controller.loadExpensesSmart();
            }
          } catch (_) {}
          if (!mounted) return;
          Navigator.of(context).pop(true);
          return;
        } else {
          try {
            ref.read(globalLoaderProvider.notifier).state = false;
          } catch (_) {}
        }
      } else {
        // Non-first month: delete and stay on detail (reload local items)
        final success = await ref
            .read(recurrentRegistryProvider.notifier)
            .deleteRecurrenceFromMonth(widget.recurring.id, monthIndex);
        if (success) {
          try {
            if (_controller != null) {
              await _controller!.loadExpensesSmart();
            } else {
              final controller = prov.Provider.of<WalletExpensesController>(
                  context,
                  listen: false);
              await controller.loadExpensesSmart();
            }
          } catch (_) {}
        }
        await _loadItems();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WalletAppBar(
        title:
            AwText.bold('Registros', color: AwColors.white, size: AwSize.s18),
        showBackArrow: true,
        barColor: AwColors.appBarColor,
        automaticallyImplyLeading: true,
        actions: [],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: TicketCard(
                notchDepth: 12,
                elevation: 8,
                color: AwColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AwSpacing.s12,
                    AwText.bold(widget.recurring.title,
                        size: AwSize.s18, color: AwColors.appBarColor),
                    AwSpacing.s6,
                    AwText.normal(
                        'Día del mes: ${widget.recurring.dayOfMonth} • ${widget.recurring.months} meses',
                        size: AwSize.s14,
                        color: AwColors.modalGrey),
                    AwSpacing.s12,
                    const AwDivider(),
                    RecurrentDetailItems(
                      items: _items,
                      onTapItem: (row) => _showActionsForItem(row),
                    ),
                    AwSpacing.s12,
                  ],
                ),
              ),
            ),
    );
  }

  void _showActionsForItem(Map<String, dynamic> row) async {
    final idx = row['month_index'] as int;
    final choice = await RecurrentItemActions.show(context);

    if (choice == 'edit') {
      await _editAmount(idx, row);
      // reload both registry and global expenses
      try {
        final controller =
            // ignore: use_build_context_synchronously
            prov.Provider.of<WalletExpensesController>(context, listen: false);
        await controller.loadExpensesSmart();
      } catch (_) {}
      await _loadItems();
    } else if (choice == 'delete') {
      await _deleteFromThisMonth(idx);
      // _deleteFromThisMonth already refreshes global state
    } else if (choice == 'delete_single') {
      final ok = await ref
          .read(recurrentRegistryProvider.notifier)
          .deleteRecurrenceSingleMonth(widget.recurring.id, idx);
      if (ok) {
        try {
          if (_controller != null) {
            await _controller!.loadExpensesSmart();
          } else {
            final controller = prov.Provider.of<WalletExpensesController>(
                context,
                listen: false);
            await controller.loadExpensesSmart();
          }
        } catch (_) {}
        await _loadItems();
        // If no items left, close page so UI updates
        if (_items.isEmpty) {
          if (mounted) Navigator.of(context).pop(true);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _reloadTimer?.cancel();
    super.dispose();
  }
}
