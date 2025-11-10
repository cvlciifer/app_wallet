import 'package:app_wallet/library_section/main_library.dart';

class Chart extends StatefulWidget {
  const Chart({super.key, required this.expenses});

  final List<Expense> expenses;

  @override
  State<Chart> createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  late List<WalletExpenseBucket> _buckets;
  late double _maxTotalExpense;
  late double _totalExpenses;

  @override
  void initState() {
    super.initState();
    _recomputeBuckets();
  }

  @override
  void didUpdateWidget(covariant Chart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.expenses, widget.expenses)) {
      // If the expenses list instance changed, recompute caches. This avoids
      // repeated expensive computations on every rebuild (e.g., when clicking
      // inside the UI) and should prevent UI pauses.
      _recomputeBuckets();
    }
  }

  void _recomputeBuckets() {
    _buckets = Category.values
        .map((c) => WalletExpenseBucket.forCategory(widget.expenses, c))
        .toList();

    _maxTotalExpense = 0;
    for (final bucket in _buckets) {
      if (bucket.totalExpenses > _maxTotalExpense) {
        _maxTotalExpense = bucket.totalExpenses;
      }
    }

    _totalExpenses = _buckets.fold(0, (sum, b) => sum + b.totalExpenses);
  }

  Color getColorForCategory(Category category) => category.color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      width: double.maxFinite,
      height: AwSize.s300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(66, 73, 73, 73),
            spreadRadius: 3,
            blurRadius: 5,
          ),
        ],
        color: AwColors.white,
      ),
      child: Column(
        children: [
          const AwText.bold(
            'Categorías v/s Cantidad',
            color: AwColors.darkBlue,
            size: AwSize.s18,
          ),
          AwSpacing.s10,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ...List.generate(7, (index) {
                      double value = _maxTotalExpense - (index * (_maxTotalExpense / 6));
                      return AwText.bold(
                        formatNumber(value),
                        size: AwSize.s10,
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
                          painter: ChartPainter(_maxTotalExpense),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: _buckets.map((bucket) {
                              return Expanded(
                                child: ChartBar(
                                  fill: bucket.totalExpenses == 0 ? 0 : bucket.totalExpenses / _maxTotalExpense,
                                  barColor: getColorForCategory(bucket.category),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      AwSpacing.s10,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _buckets.map((bucket) {
                          return Expanded(
                            child: SizedBox(
                              width: 40,
                              child: Icon(
                                categoryIcons[bucket.category],
                                color: bucket.category.color,
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
              const AwText.bold(
                'Gasto Total Acumulado:',
                size: AwSize.s18,
                color: AwColors.darkBlue,
              ),
              AwText.bold(
                formatNumber(_totalExpenses),
                size: AwSize.s18,
                color: AwColors.darkBlue,
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
      ..color = AwColors.grey.withOpacity(0.5)
      ..strokeWidth = 1.5;

    int numLines = 7;
    double heightStep = size.height / (numLines - 1);

    for (int i = 0; i < numLines; i++) {
      double yPosition = size.height - (i * heightStep * (maxTotalExpense > 0 ? 1 : 0));
      canvas.drawLine(Offset(0, yPosition), Offset(size.width, yPosition), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is ChartPainter) {
      return oldDelegate.maxTotalExpense != maxTotalExpense;
    }
    return true;
  }
}
