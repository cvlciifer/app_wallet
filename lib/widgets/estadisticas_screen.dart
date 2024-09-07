import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app_wallet/screens/expenses.dart';

class EstadisticasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> data = [
      {'category': 'Comida', 'amount': 100.0},
      {'category': 'Viajes', 'amount': 150.0},
      {'category': 'Ocio', 'amount': 200.0},
      {'category': 'Trabajo', 'amount': 50.0},
      {'category': 'Otros', 'amount': 50.0},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Estadísticas'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueAccent.shade100,
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Título en la parte superior centrado y un poco más abajo
            SizedBox(height: 32.0),
            Center(
              child: Text(
                'Estadísticas Mensuales',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.black87,
                    ),
              ),
            ),
            // Espacio entre el título y el gráfico
            SizedBox(height: 16.0),
            // Gráfico de pastel
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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
            SizedBox(height: 8.0),
            // Resumen de Datos
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen del Mes',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Total: \$${data.fold(0.0, (sum, item) => sum + item['amount']).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.0),
            // Lista de categorías
            ..._getCategoryTexts(data),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections(
      List<Map<String, dynamic>> data) {
    final total = data.fold(0.0, (sum, item) => sum + item['amount']);

    return data.map((item) {
      final category = item['category'];
      final amount = item['amount'];
      final percentage = (amount / total) * 100;

      return PieChartSectionData(
        color: _getCategoryColor(category),
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Comida':
        return Colors.blue;
      case 'Viajes':
        return Colors.red;
      case 'Ocio':
        return Colors.green;
      case 'Trabajo':
        return Colors.orange;
      case 'Otros':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  List<Widget> _getCategoryTexts(List<Map<String, dynamic>> data) {
    return data.map((item) {
      final category = item['category'];
      final amount = item['amount'];

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: _getCategoryColor(category),
            ),
            SizedBox(width: 8),
            Text(
              '$category: \$${amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pantalla Principal'),
      ),
      body: Center(
        child: Text('Página Principal'),
      ),
    );
  }
}
