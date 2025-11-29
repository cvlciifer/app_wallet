import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/core/models/recurring_expense.dart';
import 'recurrent_list_item.dart';

typedef RecurrentItemTap = void Function(RecurringExpense recurring);

class RecurrentList extends StatelessWidget {
  final List<RecurringExpense> items;
  final RecurrentItemTap? onTapItem;

  const RecurrentList({Key? key, required this.items, this.onTapItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AwText.normal('No hay gastos recurrentes aún.', color: AwColors.modalGrey),
            AwSpacing.s6,
            Center(
              child: Image(
                image: AWImage.ghost,
                fit: BoxFit.contain,
                width: 96,
                height: 96,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, __) => const AwDivider(),
      itemBuilder: (ctx, i) {
        final r = items[i];
        return RecurrentListItem(recurring: r, onTap: (rec) => onTapItem?.call(rec));
      },
    );
  }
}
