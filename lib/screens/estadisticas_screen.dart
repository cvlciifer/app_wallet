import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app_wallet/screens/expenses.dart';
import 'package:app_wallet/models/expense.dart';
import 'package:intl/intl.dart';

class EstadisticasScreen extends StatefulWidget {
  final List<Expense> expenses;

  EstadisticasScreen({Key? key, required this.expenses}) : super(key: key);

  @override
  _EstadisticasScreenState createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  double chartAngle = 0.0;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  final Map<String, IconData> categoryIcons = {
    'comida': Icons.lunch_dining,
    'viajes': Icons.flight_takeoff,
    'ocio': Icons.movie,
    'trabajo': Icons.work,
    'salud': Icons.health_and_safety,
    'servicios': Icons.design_services,
  };

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return '\$${formatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = widget.expenses.where((expense) {
      final expenseDate = expense.date;
      return expenseDate.month == selectedMonth &&
          expenseDate.year == selectedYear;
    }).toList();

    final expenseBuckets = Category.values.map((category) {
      return ExpenseBucket.forCategory(filteredExpenses, category);
    }).toList();

    final data = expenseBuckets
        .where((bucket) => bucket.totalExpenses > 0)
        .map((bucket) {
      return {
        'category': bucket.category.name,
        'amount': bucket.totalExpenses as double,
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Expenses()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen del mes y DropdownButtons fuera de la tarjeta
              const Text(
                'Resumen del mes:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dropdown para seleccionar el mes
                  DropdownButton<int>(
                    value: selectedMonth,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                            DateFormat('MMMM').format(DateTime(0, index + 1))),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        selectedMonth = value!;
                      });
                    },
                  ),
                  // Dropdown para seleccionar el año
                  DropdownButton<int>(
                    value: selectedYear,
                    items: List.generate(5, (index) {
                      int year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year'),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value!;
                      });
                    },
                  ),
                  // Muestra el total filtrado
                  Text(
                    'Total: ${formatNumber(data.fold(0.0, (sum, item) => sum + (item['amount'] as double)))}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Card(
                elevation: 10,
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                color: const Color.fromARGB(255, 242, 242,
                    242), // Cambia el color de fondo de la tarjeta aquí
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: filteredExpenses.isEmpty
                      ? const Center(
                          child: Text(
                            'No hubo gastos registrados durante este mes.',
                            style:
                                TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gráfico porcentual:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16.0),
                            GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  chartAngle += details.delta.dx * 0.01;
                                });
                              },
                              child: Transform.rotate(
                                angle: chartAngle,
                                child: SizedBox(
                                  height: 300,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _getPieChartSections(data),
                                      borderData: FlBorderData(show: false),
                                      sectionsSpace: 0,
                                      centerSpaceRadius: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ..._getCategoryTexts(data),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections(
      List<Map<String, dynamic>> data) {
    final total =
        data.fold(0.0, (sum, item) => sum + (item['amount'] as double));

    return data.map((item) {
      final category = item['category'] as String;
      final amount = item['amount'] as double;
      final percentage = (amount / total) * 100;

      return PieChartSectionData(
        color: _getCategoryColor(category),
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'comida':
        return Colors.blue;
      case 'viajes':
        return Colors.red;
      case 'ocio':
        return Colors.green;
      case 'trabajo':
        return Colors.orange;
      case 'salud':
        return Colors.purple;
      case 'servicios':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  List<Widget> _getCategoryTexts(List<Map<String, dynamic>> data) {
    return data.map((item) {
      final category = item['category'] as String;
      final amount = item['amount'] as double;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(
              categoryIcons[category],
              size: 20,
              color: _getCategoryColor(category),
            ),
            const SizedBox(width: 8),
            Text(
              '$category: ${formatNumber(amount)}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }).toList();
  }
}
