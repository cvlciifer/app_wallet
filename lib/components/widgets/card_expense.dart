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
            const AwText.bold(
              'Gasto Total Acumulado:',
              color: AwColors.blue,
            ),
            AwText.bold(
              '\$${formatNumber(totalExpenses)}',
              color: AwColors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
