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

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (ctx, index) => Dismissible(
        key: ValueKey(expenses[index]),
        direction: DismissDirection.horizontal,
        background: Container(
          color: Colors.red.withOpacity(0.7),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 30,
          ),
        ),
        secondaryBackground: Container(
          color: Colors.red.withOpacity(0.7),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 30,
          ),
        ),
        confirmDismiss: (direction) async {
          // Mostrar diálogo de confirmación
          final confirmDelete = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Confirmar eliminación'),
              content: const Text(
                  '¿Estás seguro de que quieres eliminar este gasto?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx)
                        .pop(false); // Cerrar el diálogo y NO eliminar
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(true); // Cerrar el diálogo y eliminar
                  },
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          );

          return confirmDelete ??
              false; // Si confirma eliminar, devuelve true para proceder
        },
        onDismissed: (direction) {
          onRemoveExpense(expenses[index]); // Eliminar el gasto
        },
        child: ExpenseItem(expenses[index]),
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
