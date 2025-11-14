import 'package:app_wallet/library_section/main_library.dart';

typedef MonthsCountChanged = void Function(int newCount);

class MonthsCountArrowSelector extends StatelessWidget {
  final int count;
  final int minCount;
  final int maxCount;
  final MonthsCountChanged onChanged;

  const MonthsCountArrowSelector({
    Key? key,
    required this.count,
    required this.onChanged,
    this.minCount = 1,
    this.maxCount = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canPrev = count > minCount;
    final canNext = count < maxCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left arrow: render only when previous is available, otherwise keep spacer
        if (canPrev)
          InkWell(
            onTap: () => onChanged(count - 1),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: AwColors.appBarColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.chevron_left, color: AwColors.appBarColor),
            ),
          )
        else
          const SizedBox(width: 40, height: 40),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: AwColors.appBarColor.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            // ignore: deprecated_member_use
            border: Border.all(color: AwColors.appBarColor.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AwText.bold(
                count == 1 ? '1 mes' : '$count meses',
                size: AwSize.s14,
                color: AwColors.boldBlack,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Right arrow: render only when next is available, otherwise keep spacer
        if (canNext)
          InkWell(
            onTap: () => onChanged(count + 1),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AwColors.appBarColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chevron_right, color: AwColors.appBarColor),
            ),
          )
        else
          const SizedBox(width: 40, height: 40),
      ],
    );
  }
}
