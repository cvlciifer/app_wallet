import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Asegúrate de importar intl
import 'package:app_wallet/widgets/expenses_list/expense_item.dart';
import 'package:app_wallet/models/expense.dart';

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
            onPressed: () {
              Navigator.of(ctx).pop(); // Cerrar el diálogo sin hacer nada
            },
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalles del Gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, // Alinear al inicio (izquierda)
          children: [
            const SizedBox(height: 10),
            Text(
              'Título: ${expense.title}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.left, // Alinear a la izquierda
            ),
            const SizedBox(height: 5),
            Text(
              'Categoría: ${_getCategoryName(expense.category)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.left, // Alinear a la izquierda
            ),
            const SizedBox(height: 5),
            Text(
              'Monto: ${formatNumber(expense.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.left, // Alinear a la izquierda
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return '\$${formatter.format(value)}'; // Añade el símbolo $
  }

  String _getCategoryName(Category category) {
    return category.toString().split('.').last.capitalize(); // Convierte a mayúscula la primera letra
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

// Extensión para capitalizar la primera letra
extension StringCapitalizationExtension on String {
  String capitalize() {
    if (this.isEmpty) {
      return this;
    }
    return '${this[0].toUpperCase()}${this.substring(1)}';
  }
}