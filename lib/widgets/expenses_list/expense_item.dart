import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importa el paquete intl
import 'package:app_wallet/models/expense.dart';

class ExpenseItem extends StatelessWidget {
  const ExpenseItem(this.expense, {super.key});

  final Expense expense;

  // Define un formateador para los números con '.' cada tres dígitos
  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expense.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                // Utiliza el formateador para mostrar el número formateado
                Text(
                  '\$${formatNumber(expense.amount)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(categoryIcons[expense.category]),
                    const SizedBox(width: 8),
                    Text(expense.formattedDate),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
