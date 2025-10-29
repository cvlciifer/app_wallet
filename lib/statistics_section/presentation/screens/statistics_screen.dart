import 'package:app_wallet/library_section/main_library.dart';

class EstadisticasScreen extends StatefulWidget {
  final List<Expense> expenses;

  const EstadisticasScreen({Key? key, required this.expenses}) : super(key: key);

  @override
  _EstadisticasScreenState createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool groupBySubcategory = false;

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return '\$${formatter.format(value)}';
  }

  List<Map<String, dynamic>> _getFilteredData() {
    final filteredExpenses = widget.expenses.where((expense) {
      final expenseDate = expense.date;
      return expenseDate.month == selectedMonth && expenseDate.year == selectedYear;
    }).toList();

    if (!groupBySubcategory) {
      // Group by Category
      final walletExpenseBuckets = Category.values.map((category) {
        return WalletExpenseBucket.forCategory(filteredExpenses, category);
      }).toList();

      return walletExpenseBuckets.where((bucket) => bucket.totalExpenses > 0).map((bucket) {
        return {
          'label': bucket.category.displayName,
          'amount': bucket.totalExpenses,
          'icon': categoryIcons[bucket.category],
          'color': bucket.category.color,
        };
      }).toList();
    } else {
      final Map<String, double> sums = {};
      double noSubSum = 0.0;
      for (final e in filteredExpenses) {
        if (e.subcategoryId != null && e.subcategoryId!.isNotEmpty) {
          sums[e.subcategoryId!] = (sums[e.subcategoryId!] ?? 0) + e.amount;
        } else {
          noSubSum += e.amount;
        }
      }

      final List<Map<String, dynamic>> result = [];

      for (final entry in sums.entries) {
        Subcategory? found;
        for (final list in subcategoriesByCategory.values) {
          for (final s in list) {
            if (s.id == entry.key) {
              found = s;
              break;
            }
          }
          if (found != null) break;
        }

        result.add({
          'label': found?.name ?? entry.key,
          'amount': entry.value,
          'icon': found?.icon,
          'color': found?.parent.color,
        });
      }

      if (noSubSum > 0) {
        result.add({
          'label': 'Sin subcategoría',
          'amount': noSubSum,
          'icon': Icons.category,
          'color': Colors.grey,
        });
      }
      result.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
      return result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _getFilteredData();
    final totalAmount = data.fold(0.0, (sum, item) => sum + (item['amount'] as double));

    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold(
          'Estadísticas',
          size: AwSize.s18,
          color: AwColors.white,
        ),
        automaticallyImplyLeading: true,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AwText.bold(
              'Resumen del Mes:',
              size: AwSize.s18,
              color: AwColors.boldBlack,
              fontWeight: FontWeight.bold,
            ),
            AwSpacing.s,
            WalletMonthYearSelector(
              selectedMonth: selectedMonth,
              selectedYear: selectedYear,
              onMonthChanged: (month) => setState(() => selectedMonth = month),
              onYearChanged: (year) => setState(() => selectedYear = year),
              totalAmount: totalAmount,
              formatNumber: formatNumber,
            ),
            AwSpacing.m,
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          if (groupBySubcategory) setState(() => groupBySubcategory = false);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Categoria',
                          style: TextStyle(
                            color: groupBySubcategory ? AwColors.black : AwColors.appBarColor,
                            fontSize: AwSize.s16,
                          ),
                        ),
                      ),
                      Container(height: 2, color: groupBySubcategory ? Colors.transparent : AwColors.appBarColor),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          if (!groupBySubcategory) setState(() => groupBySubcategory = true);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Subcategoria',
                          style: TextStyle(
                            color: groupBySubcategory ? AwColors.appBarColor : AwColors.black,
                            fontSize: AwSize.s16,
                          ),
                        ),
                      ),
                      Container(height: 2, color: groupBySubcategory ? AwColors.appBarColor : Colors.transparent),
                    ],
                  ),
                ),
              ],
            ),
            AwSpacing.s,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: data.isEmpty
                    ? const Center(
                        child: AwText.bold(
                          'No existen gastos registrados durante este mes.',
                          size: AwSize.s18,
                          color: AwColors.black,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AwText.bold(
                            'Gráfico Porcentual:',
                            size: AwSize.s18,
                            color: AwColors.boldBlack,
                          ),
                          AwSpacing.s,
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  WalletPieChart(data: data),
                                  AwSpacing.m,
                                  WalletCategoryList(data: data, formatNumber: formatNumber),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
