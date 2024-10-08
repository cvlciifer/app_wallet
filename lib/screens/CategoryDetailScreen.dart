import 'package:flutter/material.dart';
import 'package:app_wallet/models/expense.dart';
import 'package:intl/intl.dart';

class CategoryDetailScreen extends StatelessWidget {
  final Category category;
  final List<Expense> expenses;

  CategoryDetailScreen({Key? key, required this.category, required this.expenses}) : super(key: key);

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return '\$${formatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gastos asociados a ${category.name}',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: Theme.of(context).colorScheme.background,
        child: expenses.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 50, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'No hay gastos asociados a esta categoría durante este mes.',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Theme.of(context).colorScheme.surface,
                    child: ListTile(
                      leading: Icon(
                        categoryIcons[expense.category],
                        size: 30,
                        color: Theme.of(context).colorScheme.tertiary, // Color terciario
                      ),
                      title: Text(
                        expense.title,
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      subtitle: Text(
                        '${expense.formattedDate}\nMonto: ${formatNumber(expense.amount)}',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
