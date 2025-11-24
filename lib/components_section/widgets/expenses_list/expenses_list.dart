import 'package:app_wallet/library_section/main_library.dart';

class ExpensesList extends StatelessWidget {
  const ExpensesList({
    super.key,
    required this.expenses,
    required this.onRemoveExpense,
  });

  final List<Expense> expenses;
  final void Function(Expense expense) onRemoveExpense;

  void _showDeleteConfirmationDialog(BuildContext context, Expense expense) {
    showDialog(
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
                      onPressed: () => Navigator.of(ctx).pop(),
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
                        Navigator.of(ctx).pop();
                        onRemoveExpense(expense);
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
    DetailExpenseDialog.show(context, expense,
        onRemoveExpense: onRemoveExpense);
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(expenses[index]),
          direction: DismissDirection.horizontal,
          background: Container(
            color: Theme.of(context).colorScheme.error.withOpacity(0.75),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(
              Icons.delete,
              color: AwColors.white,
              size: 30,
            ),
          ),
          secondaryBackground: Container(
            color: Theme.of(context).colorScheme.error.withOpacity(0.75),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 30,
            ),
          ),
          confirmDismiss: (direction) async {
            _showDeleteConfirmationDialog(context, expenses[index]);
            return false;
          },
          child: InkWell(
            onTap: () => _onExpenseTap(context, expenses[index]),
            child: ExpenseItem(expenses[index]),
          ),
        ),
      ),
    );
  }
}
