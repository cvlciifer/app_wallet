import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/core/models/recurring_expense.dart';

typedef RecurrentTapCallback = void Function(RecurringExpense recurring);

class RecurrentListItem extends StatelessWidget {
  final RecurringExpense recurring;
  final RecurrentTapCallback? onTap;

  const RecurrentListItem({Key? key, required this.recurring, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      title: AwText.bold(recurring.title, color: AwColors.boldBlack),
      subtitle: AwText(
          text:
              'Monto: ${recurring.amount.toInt()} • ${recurring.months} meses • Día ${recurring.dayOfMonth}'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => onTap?.call(recurring),
    );
  }
}
