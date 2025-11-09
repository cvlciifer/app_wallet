import 'package:app_wallet/library_section/main_library.dart';

class AwAlert {
  static Future<void> showTicketInfo(
    BuildContext context, {
    required String title,
    required String content,
    Color? titleColor,
    double titleSize = AwSize.s20,
    double contentSize = AwSize.s14,
    String okLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: TicketCard(
          roundTopCorners: true,
          topCornerRadius: 10,
          compactNotches: true,
          overlays: [
            Positioned(
              top: -10,
              right: -10,
              child: Material(
                color: Colors.white,
                child: IconButton(
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AwText.bold(
                title,
                color: titleColor ?? AwColors.appBarColor,
                size: titleSize,
              ),
              const SizedBox(height: 8),
              AwText.normal(
                content,
                size: contentSize,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  WalletButton.textButton(
                    buttonText: okLabel,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
