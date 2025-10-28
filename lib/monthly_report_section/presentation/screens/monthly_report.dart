import 'package:app_wallet/library_section/main_library.dart';

class InformeMensualScreen extends StatefulWidget {
  final List<Expense> expenses;

  const InformeMensualScreen({Key? key, required this.expenses}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _InformeMensualScreenState createState() => _InformeMensualScreenState();
}

class _InformeMensualScreenState extends State<InformeMensualScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = widget.expenses.where((expense) {
      return expense.date.month == selectedMonth && expense.date.year == selectedYear;
    }).toList();

    final double totalExpenses = filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);
    final expenseBuckets = Category.values.map((category) {
      return WalletExpenseBucket.forCategory(filteredExpenses, category);
    }).toList();

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
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                          alignment: Alignment.centerLeft,
                          backgroundColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: () {
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
                        child: Row(
                          children: [
                            Icon(
                              categoryIcons[bucket.category],
                              size: 30,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bucket.category.displayName,
                                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total: ${formatNumber(bucket.totalExpenses)}',
                                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(context).dividerColor,
                      ),
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
