import 'package:app_wallet/library_section/main_library.dart';

class ExpenseItem extends StatelessWidget {
  const ExpenseItem(this.expense, {super.key});

  final Expense expense;

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      child: TicketCard(
        compactNotches: true,
        roundTopCorners: true,
        topCornerRadius: 10,
        elevation: 10,
        color: AwColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AwText.bold(
              expense.title,
              color: AwColors.boldBlack,
            ),
            AwSpacing.xs,
            Row(
              children: [
                AwText(
                  text: '\$${formatNumber(expense.amount)}',
                  size: AwSize.s16,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      categoryIcons[expense.category],
                      color: expense.category.color,
                    ),
                    AwSpacing.w,
                    AwText.bold(expense.formattedDate),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
