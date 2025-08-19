import 'package:app_wallet/library/main_library.dart';

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
      ExpenseBucket.forCategory(expenses, Category.salud),
      ExpenseBucket.forCategory(expenses, Category.servicios),
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
        return AwColors.darkBlue;
      case Category.ocio:
        return AwColors.darkBlue;
      case Category.viajes:
        return AwColors.darkBlue;
      case Category.trabajo:
        return AwColors.darkBlue;
      case Category.servicios:
        return AwColors.darkBlue;
      default:
        return AwColors.darkBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      width: double.maxFinite,
      height: AwSize.s300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // ignore: deprecated_member_use
        color: AwColors.cyan.withOpacity(0.2),
      ),
      child: Column(
        children: [
          // Título del gráfico
          const Text(
            'Categorías v/s Cantidad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AwColors.darkBlue,
            ),
          ),
          AwSpacing.s10, // Espacio entre el título y el gráfico
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Barra lateral con valores y más espacio
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ...List.generate(7, (index) {
                      double value =
                          maxTotalExpense - (index * (maxTotalExpense / 6));
                      return Text(
                        formatNumber(value),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AwColors.darkBlue,
                            fontSize: AwSize.s10),
                      );
                    }),
                    AwSpacing.s10,
                  ],
                ),
                AwSpacing.s,

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
                      AwSpacing.s10,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: buckets.map((bucket) {
                          return Expanded(
                            child: SizedBox(
                              width: 40,
                              child: Icon(
                                categoryIcons[bucket.category],
                                color: AwColors.blue,
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
                      color: AwColors.darkBlue,
                    ),
              ),
              Text(
                formatNumber(totalExpenses),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AwColors.darkBlue,
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
      // ignore: deprecated_member_use
      ..color = AwColors.grey.withOpacity(0.5)
      ..strokeWidth = 1.5;

    // Determine the number of lines and their positions
    int numLines = 7; // You can keep this as is
    double heightStep =
        size.height / (numLines - 1); // Adjust to cover 0 to max

    for (int i = 0; i < numLines; i++) {
      // Calculate the y position for each line based on the height
      double yPosition =
          size.height - (i * heightStep * (maxTotalExpense > 0 ? 1 : 0));
      canvas.drawLine(
          Offset(0, yPosition), Offset(size.width, yPosition), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
