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
  bool _initializedFromController = false;
  // PageView controller and current page index for the charts carousel
  late PageController _pageController;
  int _currentChartPage = 0;

  List<int> getAvailableYears() {
    final years = widget.expenses.map((e) => e.date.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List<int> getAvailableMonthsForYear(int year) {
    final months = widget.expenses.where((e) => e.date.year == year).map((e) => e.date.month).toSet().toList();
    months.sort();
    return months;
  }

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
    if (!_initializedFromController) {
      try {
        final controller = context.read<WalletExpensesController>();
        final mf = controller.monthFilter;
        if (mf != null) {
          selectedMonth = mf.month;
          selectedYear = mf.year;
        }
      } catch (_) {}
      _initializedFromController = true;
    }
    // Aseguramos que las listas de años y meses disponibles reflejen los gastos
    final expenses =
        widget.expenses.isNotEmpty ? widget.expenses : (context.read<WalletExpensesController>().allExpenses);
    final availableYears = expenses.map((e) => e.date.year).toSet().toList();
    if (!availableYears.contains(selectedYear) && availableYears.isNotEmpty) {
      selectedYear = availableYears.first;
    }
    final availableMonths =
        expenses.where((e) => e.date.year == selectedYear).map((e) => e.date.month).toSet().toList();
    availableMonths.sort();
    if (!availableMonths.contains(selectedMonth) && availableMonths.isNotEmpty) {
      selectedMonth = availableMonths.first;
    }

    final data = _getFilteredData();
    // Lista de gastos filtrados por mes/año para pasar al Chart
    final filteredExpensesList =
        expenses.where((e) => e.date.month == selectedMonth && e.date.year == selectedYear).toList();

    // inicializar page controller si no está ya
    _pageController = PageController(initialPage: _currentChartPage);
    final totalAmount = data.fold(0.0, (sum, item) => sum + (item['amount'] as double));

    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold(
          'Estadística Mensual',
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
            AwSpacing.s,
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
            WalletMonthYearSelector(
              selectedMonth: selectedMonth,
              selectedYear: selectedYear,
              onMonthChanged: (month) => setState(() => selectedMonth = month),
              onYearChanged: (year) => setState(() => selectedYear = year),
              availableMonths: availableMonths,
              availableYears: availableYears,
              totalAmount: totalAmount,
              formatNumber: formatNumber,
            ),
            AwSpacing.s,
            Expanded(
              child: Padding(
                // Reducimos el padding horizontal para dar más espacio a los gráficos
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
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
                            'Gráficos',
                            size: AwSize.s18,
                            color: AwColors.boldBlack,
                          ),
                          AwSpacing.s,
                          SizedBox(
                            height: AwSize.s300,
                            child: Column(
                              children: [
                                Expanded(
                                  child: PageView(
                                    controller: _pageController,
                                    onPageChanged: (idx) => setState(() => _currentChartPage = idx),
                                    children: [
                                      // Página 1: gráfico de torta
                                      WalletPieChart(data: data),
                                      // Página 2: gráfico de barras (Chart) usando los gastos filtrados
                                      Chart(expenses: filteredExpensesList),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Indicador de página (dots)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(2, (i) {
                                    final bool active = _currentChartPage == i;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                      width: active ? 14 : 10,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: active ? AwColors.appBarColor : AwColors.grey,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          AwSpacing.s,
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
