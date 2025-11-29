import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

class ExpensesList extends StatefulWidget {
  const ExpensesList({
    super.key,
    required this.expenses,
    required this.onRemoveExpense,
  });

  final List<Expense> expenses;
  final Future<void> Function(Expense expense) onRemoveExpense;

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  late List<Expense> _items;

  @override
  void initState() {
    super.initState();
    _items = List<Expense>.from(widget.expenses);
  }

  @override
  void didUpdateWidget(covariant ExpensesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.expenses.map((e) => e.id).toList();
    final newIds = widget.expenses.map((e) => e.id).toList();
    if (oldIds.length != newIds.length || !_listEquals(oldIds, newIds)) {
      setState(() {
        _items = List<Expense>.from(widget.expenses);
      });
    }
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<bool?> _showDeleteConfirmationDialog(
      BuildContext context, Expense expense) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AwText.bold(
          'Eliminar Gasto',
          color: AwColors.red,
        ),
        content: const AwText(
            text: 'Estás a punto de borrar un gasto. ¿Estás seguro?'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: SizedBox(
                    height: AwSize.s48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AwColors.blueGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AwSize.s16),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Cancelar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AwColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: SizedBox(
                    height: AwSize.s48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AwColors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AwSize.s16),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Continuar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AwColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onExpenseTap(BuildContext context, Expense expense) {
    try {
      DetailExpenseDialog.show(context, expense,
          onRemoveExpense: widget.onRemoveExpense);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (ctx, index) {
          final expense = _items[index];

          return Dismissible(
            key: ValueKey(expense.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Theme.of(context).colorScheme.error.withOpacity(0.75),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.delete,
                    color: AwColors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
            secondaryBackground: Container(
              color: Theme.of(context).colorScheme.error.withOpacity(0.75),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                final confirmed =
                    await _showDeleteConfirmationDialog(context, expense);
                if (confirmed != true) return false;

                bool offline = false;
                try {
                  final conn = await Connectivity().checkConnectivity();
                  offline = conn == ConnectivityResult.none;
                } catch (_) {}

                try {
                  riverpod.ProviderScope.containerOf(context, listen: false)
                      .read(globalLoaderProvider.notifier)
                      .state = true;
                } catch (_) {}

                bool success = false;
                try {
                  await widget.onRemoveExpense(expense);
                  success = true;
                } catch (e) {
                  try {
                    WalletPopup.showNotificationError(
                      // ignore: use_build_context_synchronously
                      context: Navigator.of(context, rootNavigator: true)
                              .overlay
                              ?.context ??
                          context,
                      title: 'Error al eliminar gasto.',
                    );
                  } catch (_) {}
                } finally {
                  try {
                    riverpod.ProviderScope.containerOf(context, listen: false)
                        .read(globalLoaderProvider.notifier)
                        .state = false;
                  } catch (_) {}
                }

                if (success) {
                  final overlayCtx = Navigator.of(context).overlay?.context;
                  final popupCtx = Navigator.of(context, rootNavigator: true)
                          .overlay
                          ?.context ??
                      overlayCtx ??
                      context;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    try {
                      if (offline) {
                        Future.microtask(() async {
                          await Future.delayed(
                              const Duration(milliseconds: 120));
                          try {
                            WalletPopup.showNotificationSuccess(
                              // ignore: use_build_context_synchronously
                              context: popupCtx,
                              title: 'Gasto eliminado correctamente.',
                              message: const AwText.normal(
                                'Será sincronizado cuando exista internet',
                                color: AwColors.white,
                                size: AwSize.s14,
                              ),
                              visibleTime: 2,
                              isDismissible: true,
                            );
                          } catch (_) {}
                        });
                      } else {
                        try {
                          WalletPopup.showNotificationSuccess(
                            context: popupCtx,
                            title: 'Gasto eliminado correctamente.',
                          );
                        } catch (_) {}
                      }
                    } catch (_) {}
                  });
                }

                return success;
              }
              return false;
            },
            onDismissed: (_) {
              if (mounted) {
                setState(() {
                  _items.removeWhere((e) => e.id == expense.id);
                });
              }
            },
            child: InkWell(
              onTap: () => _onExpenseTap(context, expense),
              child: ExpenseItem(expense),
            ),
          );
        },
      ),
    );
  }
}
