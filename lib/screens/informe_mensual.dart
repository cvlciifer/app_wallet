import 'package:app_wallet/library/main_library.dart';

class InformeMensualScreen extends StatefulWidget {
  final List<Expense> expenses;

  InformeMensualScreen({Key? key, required this.expenses}) : super(key: key);

  @override
  _InformeMensualScreenState createState() => _InformeMensualScreenState();
}

class _InformeMensualScreenState extends State<InformeMensualScreen> {
  int selectedMonth = DateTime.now().month; // Mes seleccionado
  int selectedYear = DateTime.now().year; // Año seleccionado
  int _currentBottomNavIndex = 2; // Informes está en el índice 2

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return '\$${formatter.format(value)}';
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
      case 1: // Estadísticas
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => EstadisticasScreen(
              expenses: widget.expenses,
            ),
          ),
        );
        break;
      case 2: // Informes (ya estamos aquí)
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

  // void _showUserInfo() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Mi Wallet'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text('Total de gastos: ${widget.expenses.length}'),
  //             const SizedBox(height: 8),
  //             Text('Mes actual: ${_getMonthName(selectedMonth)} $selectedYear'),
  //             const SizedBox(height: 8),
  //             Text('Total del mes: ${formatNumber(_getTotalForMonth())}'),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: const Text('Cerrar'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               // Navegación a configuración si la tienes
  //               // Navigator.of(context).pushNamed('/settings');
  //             },
  //             child: const Text('Configuración'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // String _getMonthName(int month) {
  //   const months = [
  //     'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  //     'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  //   ];
  //   return months[month - 1];
  // }

  // double _getTotalForMonth() {
  //   final filteredExpenses = widget.expenses.where((expense) {
  //     return expense.date.month == selectedMonth &&
  //         expense.date.year == selectedYear;
  //   }).toList();

  //   return filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  // }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = widget.expenses.where((expense) {
      return expense.date.month == selectedMonth && expense.date.year == selectedYear;
    }).toList();

    // Calcular el total de gastos
    final double totalExpenses = filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);

    // Agrupar los gastos filtrados por categoría usando ExpenseBucket
    final expenseBuckets = Category.values.map((category) {
      return WalletExpenseBucket.forCategory(filteredExpenses, category);
    }).toList();

    return Scaffold(
      appBar: const WalletAppBar(
        title: AwText.bold(
          'Informe Mensual',
          size: AwSize.s18,
          color: AwColors.white,
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: Theme.of(context).colorScheme.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total de Gastos: ${formatNumber(totalExpenses)}',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 22,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Selecciona Año y Mes para Filtrar:',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: selectedMonth,
                    isExpanded: true,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          DateFormat('MMMM').format(DateTime(0, index + 1)),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        selectedMonth = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: DropdownButton<int>(
                    value: selectedYear,
                    isExpanded: true,
                    items: List.generate(5, (index) {
                      int year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(
                          year.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: expenseBuckets.length,
                itemBuilder: (context, index) {
                  final bucket = expenseBuckets[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    color: Theme.of(context).colorScheme.surface,
                    child: ListTile(
                      leading: Icon(
                        categoryIcons[bucket.category],
                        size: 30,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      title: Text(
                        bucket.category.name,
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      subtitle: Text(
                        'Total: ${formatNumber(bucket.totalExpenses)}',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        final categoryExpenses = filteredExpenses.where((expense) {
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: WalletBottomAppBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }
}
