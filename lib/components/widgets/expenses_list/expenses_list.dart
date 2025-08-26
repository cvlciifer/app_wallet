import 'package:app_wallet/library/main_library.dart';

class ExpensesList extends StatelessWidget {
  const ExpensesList({
    super.key,
    required this.expenses,
    required this.onRemoveExpense,
  });

  final List<Expense> expenses;
  final void Function(Expense expense) onRemoveExpense;

// transformar esto a un componente independiente y que se pueda llamar el dialog y sea customizable desde la llamada
  void _showDeleteConfirmationDialog(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AwText.bold(
          'Eliminar Gasto',
          color: AwColors.red,
        ),
        content: const AwText(text: 'Estás a punto de borrar un gasto. ¿Estás seguro?'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              WalletButton.primaryButton(
                buttonText: 'Cancelar',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              const SizedBox(width: 8),
              WalletButton.primaryButton(
                buttonText: 'Continuar',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onRemoveExpense(expense);
                  WalletPopup.showNotificationSuccess(context: context, title: 'Gasto eliminado correctamente');
                },
                backgroundColor: AwColors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onExpenseTap(BuildContext context, Expense expense) {
    DetailExpenseDialog.show(context, expense);
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
              color: Colors.white,
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
