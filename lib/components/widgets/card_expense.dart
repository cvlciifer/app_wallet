import 'package:app_wallet/library/main_library.dart';

class TotalExpensesCard extends StatelessWidget {
  const TotalExpensesCard({
    Key? key,
    required this.totalExpenses,
  }) : super(key: key);

  final double totalExpenses;

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(15),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gasto Total Acumulado:',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AwColors.blue,
                  ),
            ),
            Text(
              '\$${formatNumber(totalExpenses)}',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AwColors.blue,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
