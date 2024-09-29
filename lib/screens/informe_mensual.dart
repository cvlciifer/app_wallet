import 'package:flutter/material.dart';
import 'package:app_wallet/models/expense.dart';
import 'package:intl/intl.dart';
import 'package:app_wallet/screens/CategoryDetailScreen.dart';

class InformeMensualScreen extends StatefulWidget {
  final List<Expense> expenses;

  InformeMensualScreen({Key? key, required this.expenses}) : super(key: key);

  @override
  _InformeMensualScreenState createState() => _InformeMensualScreenState();
}

class _InformeMensualScreenState extends State<InformeMensualScreen> {
  int selectedMonth = DateTime.now().month; // Mes seleccionado

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es'); 
    return '\$${formatter.format(value)}'; 
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar gastos por el mes seleccionado
    final filteredExpenses = widget.expenses.where((expense) {
      return expense.date.month == selectedMonth;
    }).toList();

    // Calcular el total de gastos
    final double totalExpenses = filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);

    // Agrupar los gastos filtrados por categoría usando ExpenseBucket
    final expenseBuckets = Category.values.map((category) {
      return ExpenseBucket.forCategory(filteredExpenses, category);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Informe Mensual',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Row para el monto total y el filtro de meses
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Total de Gastos: ${formatNumber(totalExpenses)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 16), // Espacio entre el texto y el dropdown
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(DateFormat('MMMM').format(DateTime(0, index + 1))),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      selectedMonth = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            // Mostrar los gastos agrupados por categoría
            Expanded(
              child: ListView.builder(
                itemCount: expenseBuckets.length,
                itemBuilder: (context, index) {
                  final bucket = expenseBuckets[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: Icon(
                        categoryIcons[bucket.category],
                        size: 30,
                        color: Colors.blue,
                      ),
                      title: Text(
                        bucket.category.name,
                        style: const TextStyle(fontSize: 16),
                      ),
                      subtitle: Text(
                        'Total: ${formatNumber(bucket.totalExpenses)}',
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        // Filtrar los gastos de la categoría seleccionada
                        final categoryExpenses = filteredExpenses.where((expense) {
                          return expense.category == bucket.category;
                        }).toList();

                        // Navegar a la pantalla de detalles
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => CategoryDetailScreen(
                              category: bucket.category,
                              expenses: categoryExpenses,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
