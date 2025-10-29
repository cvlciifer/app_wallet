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

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return '\$${formatter.format(value)}';
  }

  List<Map<String, dynamic>> _getFilteredData() {
    final filteredExpenses = widget.expenses.where((expense) {
      final expenseDate = expense.date;
      return expenseDate.month == selectedMonth && expenseDate.year == selectedYear;
    }).toList();

    final walletExpenseBuckets = Category.values.map((category) {
      return WalletExpenseBucket.forCategory(filteredExpenses, category);
    }).toList();

    return walletExpenseBuckets.where((bucket) => bucket.totalExpenses > 0).map((bucket) {
      return {
        'category': bucket.category.displayName,
        'amount': bucket.totalExpenses,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = _getFilteredData();
    final totalAmount = data.fold(0.0, (sum, item) => sum + (item['amount'] as double));

    return Scaffold(
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
        child: SingleChildScrollView(
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
              Card(
                elevation: 10,
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                color: AwColors.greyLight,
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
                            AwSpacing.m,
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
    );
  }
}
