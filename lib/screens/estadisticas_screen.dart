import 'package:app_wallet/library/main_library.dart';

class EstadisticasScreen extends StatefulWidget {
  final List<Expense> expenses;

  const EstadisticasScreen({Key? key, required this.expenses}) : super(key: key);

  @override
  _EstadisticasScreenState createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  int _currentBottomNavIndex = 1; // Estadísticas está en el índice 1

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
        'category': bucket.category.name,
        'amount': bucket.totalExpenses,
      };
    }).toList();
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });
    
    switch (index) {
      case 0: // Home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (ctx) => const WalletHomePage(),
          ),
          (route) => false,
        );
        break;
      case 1: // Estadísticas (ya estamos aquí)
        break;
      case 2: // Informes
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => InformeMensualScreen(
              expenses: widget.expenses,
            ),
          ),
        );
        break;
      case 3: // MiWallet
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => const WalletProfilePage(),
          ),
        );
        break;
    }
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
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen del mes:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              WalletMonthYearSelector(
                selectedMonth: selectedMonth,
                selectedYear: selectedYear,
                onMonthChanged: (month) => setState(() => selectedMonth = month),
                onYearChanged: (year) => setState(() => selectedYear = year),
                totalAmount: totalAmount,
                formatNumber: formatNumber,
              ),
              const SizedBox(height: 16.0),
              Card(
                elevation: 10,
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                color: const Color.fromARGB(255, 242, 242, 242),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: data.isEmpty
                      ? const Center(
                          child: Text(
                            'No hubo gastos registrados durante este mes.',
                            style: TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gráfico porcentual:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16.0),
                            WalletPieChart(data: data),
                            const SizedBox(height: 16.0),
                            WalletCategoryList(data: data, formatNumber: formatNumber),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: WalletBottomAppBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _handleBottomNavTap,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción para agregar nuevo gasto
          Navigator.of(context).pushNamed('/add-expense');
        },
        backgroundColor: AwColors.appBarColor,
        child: const Icon(Icons.add, color: AwColors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}