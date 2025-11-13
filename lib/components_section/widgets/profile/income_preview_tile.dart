import 'package:app_wallet/library_section/main_library.dart';

class IncomePreviewTile extends StatelessWidget {
  final String monthLabel;
  final String fijoText;
  final String imprevistoText;
  final String totalText;
  final VoidCallback? onTap;

  const IncomePreviewTile({
    Key? key,
    required this.monthLabel,
    required this.fijoText,
    required this.imprevistoText,
    required this.totalText,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AwColors.appBarColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AwText.normal(
              monthLabel,
              size: AwSize.s14,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AwText.normal(
                        'Fijo: $fijoText',
                        size: AwSize.s12,
                        color: AwColors.black54,
                      ),
                      const SizedBox(height: 4),
                      AwText.normal(
                        'Imprevisto: $imprevistoText',
                        size: AwSize.s12,
                        color: AwColors.modalGrey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AwText.bold(
                      totalText,
                      size: AwSize.s14,
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
