import 'package:app_wallet/library/main_library.dart';

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
        title: const Text('Eliminar Gasto'),
        content: const Text('Estás a punto de borrar un gasto. ¿Estás seguro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // Cerrar el diálogo
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Cerrar el diálogo
              onRemoveExpense(expense); // Eliminar el gasto
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _onExpenseTap(BuildContext context, Expense expense) {
    DetailExpenseDialog.show(
        context, expense); // Llama a la clase DetailExpenseDialog
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
            return false; // No eliminar hasta que se confirme en el diálogo
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
