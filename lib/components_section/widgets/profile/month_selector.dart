import 'package:app_wallet/library_section/main_library.dart';

typedef MonthChanged = void Function(int offsetChange);

class MonthSelector extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canPrev;
  final bool canNext;

  const MonthSelector({
    Key? key,
    required this.month,
    required this.onPrev,
    required this.onNext,
    this.canPrev = true,
    this.canNext = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // chevron
        InkWell(
          onTap: canPrev ? onPrev : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: canPrev
                  ? AwColors.appBarColor.withOpacity(0.08)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_left,
                color: canPrev ? AwColors.appBarColor : AwColors.grey),
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Container(
              key: ValueKey('${month.year}-${month.month}'),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: AwColors.appBarColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AwColors.appBarColor.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AwText.bold(
                        toBeginningOfSentenceCase(
                                DateFormat('MMMM', 'es').format(month)) ??
                            DateFormat('MMMM', 'es').format(month),
                        size: AwSize.s14,
                        color: AwColors.boldBlack,
                      ),
                      AwSpacing.s6,
                      AwText.normal(
                        '${month.year}',
                        size: AwSize.s12,
                        color: AwColors.modalGrey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),
        InkWell(
          onTap: canNext ? onNext : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: canNext
                  ? AwColors.appBarColor.withOpacity(0.08)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_right,
                color: canNext ? AwColors.appBarColor : AwColors.grey),
          ),
        ),
      ],
    );
  }
}
