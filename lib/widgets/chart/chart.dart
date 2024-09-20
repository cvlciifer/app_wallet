import 'package:flutter/material.dart';
import 'package:app_wallet/models/expense.dart';
import 'package:app_wallet/widgets/chart/chart_bar.dart';
import 'package:intl/intl.dart';

class Chart extends StatelessWidget {
  const Chart({super.key, required this.expenses});

  final List<Expense> expenses;

  // Formateador para los números con '.' cada tres dígitos
  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return '\$${formatter.format(value)}'; // Añade el símbolo $
  }

  List<ExpenseBucket> get buckets {
    return [
      ExpenseBucket.forCategory(expenses, Category.comida),
      ExpenseBucket.forCategory(expenses, Category.ocio),
      ExpenseBucket.forCategory(expenses, Category.viajes),
      ExpenseBucket.forCategory(expenses, Category.trabajo),
      ExpenseBucket.forCategory(expenses, Category.categoria),
    ];
  }

  double get maxTotalExpense {
    double maxTotalExpense = 0;

    for (final bucket in buckets) {
      if (bucket.totalExpenses > maxTotalExpense) {
        maxTotalExpense = bucket.totalExpenses;
      }
    }

    return maxTotalExpense;
  }

  double get totalExpenses {
    return buckets.fold(0, (sum, bucket) => sum + bucket.totalExpenses);
  }

  Color getColorForCategory(Category category) {
    switch (category) {
      case Category.comida:
        return const Color.fromARGB(255, 54, 118, 158);
      case Category.ocio:
        return const Color.fromARGB(255, 5, 71, 95);
      case Category.viajes:
        return const Color(0xFF88B0BF);
      case Category.trabajo:
        return const Color.fromARGB(255, 11, 106, 128);
      default:
        return const Color.fromARGB(255, 12, 140, 187);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      width: double.maxFinite,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFCEE4F2),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Barra lateral con valores y más espacio
                Column(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceAround, // Aumenta el espacio entre los números
                  children: [
                    ...List.generate(7, (index) {
                      double value =
                          maxTotalExpense - (index * (maxTotalExpense / 6));
                      return Text(
                        formatNumber(value),
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 11),
                      );
                    }),
                    const SizedBox(height: 0), // Espacio en blanco debajo del 0
                  ],
                ),
                const SizedBox(width: 8),
                // Gráfico principal ajustado
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          painter: ChartPainter(maxTotalExpense),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: buckets.map((bucket) {
                              return Expanded(
                                child: ChartBar(
                                  fill: bucket.totalExpenses == 0
                                      ? 0
                                      : bucket.totalExpenses / maxTotalExpense,
                                  barColor:
                                      getColorForCategory(bucket.category),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Ajustamos los iconos para que se alineen con las barras
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: buckets.map((bucket) {
                          return Expanded(
                            child: SizedBox(
                              width: 40,
                              child: Icon(
                                categoryIcons[bucket.category],
                                color: const Color(0xFF03738C),
                                size: 22,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gasto Total Acumulado:',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 8, 64, 110),
                    ),
              ),
              // Aquí ya no necesitas agregar otro símbolo de dólar
              Text(
                formatNumber(
                    totalExpenses), // El método formatNumber ya lo añade
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 8, 64, 110),
                    ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final double maxTotalExpense;

  ChartPainter(this.maxTotalExpense);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1.5;

    int numLines = 6; // Número de líneas entre el valor mínimo y máximo
    double heightStep = size.height / (numLines); // Divide la altura en segmentos iguales

    for (int i = 0; i <= numLines; i++) {
      // Recalcula la posición para que la primera línea esté abajo y la última arriba
      double yPosition = size.height - (i * heightStep);
      canvas.drawLine(Offset(0, yPosition), Offset(size.width, yPosition), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

