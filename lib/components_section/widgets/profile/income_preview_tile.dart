import 'package:app_wallet/library_section/main_library.dart';

class IncomePreviewTile extends StatelessWidget {
  final String monthLabel;
  final String fijoText;
  final String imprevistoText;
  final String totalText;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const IncomePreviewTile({
    Key? key,
    required this.monthLabel,
    required this.fijoText,
    required this.imprevistoText,
    required this.totalText,
    this.onTap,
    this.onEdit,
    this.onDelete,
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
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AwColors.white,
                  child: Icon(Icons.calendar_month,
                      size: AwSize.s16, color: AwColors.appBarColor),
                ),
                AwSpacing.w,
                AwText.normal(
                  monthLabel,
                  size: AwSize.s14,
                ),
              ],
            ),
            AwSpacing.s,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AwText.normal(
                        'Fijo:$fijoText',
                        size: AwSize.s12,
                        color: AwColors.black54,
                      ),
                      AwSpacing.xs,
                      AwText.normal(
                        'Imprevisto:$imprevistoText',
                        size: AwSize.s12,
                        color: AwColors.modalGrey,
                      ),
                    ],
                  ),
                ),
                AwSpacing.w12,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AwText.bold(
                      'Total:$totalText',
                      size: AwSize.s14,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: onEdit,
                            tooltip: 'Editar',
                          ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 18, color: AwColors.redAccent),
                            onPressed: onDelete,
                            tooltip: 'Eliminar',
                          ),
                      ],
                    )
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
