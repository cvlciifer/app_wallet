import 'package:app_wallet/library_section/main_library.dart';

class InformeMensualScreen extends StatefulWidget {
  final List<Expense> expenses;

  const InformeMensualScreen({Key? key, required this.expenses})
      : super(key: key);

  @override
  _InformeMensualScreenState createState() => _InformeMensualScreenState();
}

class _InformeMensualScreenState extends State<InformeMensualScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool _initializedFromController = false;

  @override
  void initState() {
    super.initState();
    _initializeSelectedMonthYear();
  }

  @override
  void didUpdateWidget(covariant InformeMensualScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses != widget.expenses) {
      _initializeSelectedMonthYear();
    }
  }

  void _initializeSelectedMonthYear() {
    final expenses = widget.expenses.isNotEmpty
        ? widget.expenses
        : (context.read<WalletExpensesController>().allExpenses);
    final years = expenses.map((e) => e.date.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    if (years.isNotEmpty) {
      selectedYear = years.first;
    }
    final months = expenses
        .where((e) => e.date.year == selectedYear)
        .map((e) => e.date.month)
        .toSet()
        .toList();
    months.sort();
    if (months.isNotEmpty) {
      selectedMonth = months.first;
    }
  }

  List<int> getAvailableYears() {
    final controller =
        Provider.of<WalletExpensesController>(context, listen: false);
    final source =
        widget.expenses.isNotEmpty ? widget.expenses : controller.allExpenses;
    final years = source.map((e) => e.date.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List<int> getAvailableMonthsForYear(int year) {
    final controller =
        Provider.of<WalletExpensesController>(context, listen: false);
    final source =
        widget.expenses.isNotEmpty ? widget.expenses : controller.allExpenses;
    final months = source
        .where((e) => e.date.year == year)
        .map((e) => e.date.month)
        .toSet()
        .toList();
    months.sort();
    return months;
  }

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return '\$${formatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    // Listen to controller so reports refresh when local data changes (offline-friendly)
    if (!_initializedFromController) {
      try {
        final controller =
            Provider.of<WalletExpensesController>(context, listen: false);
        final mf = controller.monthFilter;
        if (mf != null) {
          selectedMonth = mf.month;
          selectedYear = mf.year;
        }
      } catch (_) {}
      _initializedFromController = true;
    }

    final controller = Provider.of<WalletExpensesController>(context);
    final sourceExpenses =
        widget.expenses.isNotEmpty ? widget.expenses : controller.allExpenses;
    final filteredExpenses = sourceExpenses.where((expense) {
      return expense.date.month == selectedMonth &&
          expense.date.year == selectedYear;
    }).toList();

    final double totalExpenses =
        filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);
    final expenseBuckets = Category.values.map((category) {
      return WalletExpenseBucket.forCategory(filteredExpenses, category);
    }).toList();

    // Ordenar: primero categorías con gastos (totalExpenses > 0),
    // luego las que no tienen gastos. Dentro de cada grupo ordenamos
    // por total descendente para mostrar las categorías más relevantes arriba.
    expenseBuckets.sort((a, b) {
      final aHas = a.totalExpenses > 0;
      final bHas = b.totalExpenses > 0;
      if (aHas && !bHas) return -1;
      if (!aHas && bHas) return 1;
      return b.totalExpenses.compareTo(a.totalExpenses);
    });

    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold(
          'Informe Mensual',
          size: AwSize.s18,
          color: AwColors.white,
        ),
        automaticallyImplyLeading: true,
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
        child: Column(
          children: [
            // Floating card at the top
            Material(
              elevation: 12,
              color: AwColors.white,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: AwColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total de Gastos: ${formatNumber(totalExpenses)}',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AwSpacing.s12,
                    Text(
                      'Selecciona Año y Mes para Filtrar:',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AwSpacing.s,
                    Builder(builder: (context) {
                      final availableYears = getAvailableYears();
                      if (!availableYears.contains(selectedYear) &&
                          availableYears.isNotEmpty) {
                        selectedYear = availableYears.first;
                      }
                      final availableMonths =
                          getAvailableMonthsForYear(selectedYear);
                      if (!availableMonths.contains(selectedMonth) &&
                          availableMonths.isNotEmpty) {
                        selectedMonth = availableMonths.first;
                      }

                      return WalletMonthYearSelector(
                        selectedMonth: selectedMonth,
                        selectedYear: selectedYear,
                        onMonthChanged: (m) =>
                            setState(() => selectedMonth = m),
                        onYearChanged: (y) => setState(() {
                          selectedYear = y;
                          final availableMonths = getAvailableMonthsForYear(y);
                          if (availableMonths.isNotEmpty) {
                            selectedMonth = availableMonths.first;
                          } else {
                            selectedMonth = 1;
                          }
                        }),
                        availableMonths: availableMonths,
                        availableYears: availableYears,
                        totalAmount: totalExpenses,
                        showTotal: false,
                        formatNumber: (d) => formatNumber(d),
                      );
                    }),
                  ],
                ),
              ),
            ),

            AwSpacing.m,

            // List below the card
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: expenseBuckets.length,
                itemBuilder: (context, index) {
                  final bucket = expenseBuckets[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SettingsCard(
                        title: bucket.category.displayName,
                        icon: categoryIcons[bucket.category] ?? Icons.category,
                        iconColor: bucket.category.color,
                        subtitle:
                            'Total: ${formatNumber(bucket.totalExpenses)}',
                        onTap: () {
                          final categoryExpenses =
                              filteredExpenses.where((expense) {
                            return expense.category == bucket.category;
                          }).toList();
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
                      AwSpacing.s6,
                    ],
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
