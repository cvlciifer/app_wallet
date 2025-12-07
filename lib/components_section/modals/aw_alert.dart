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
      // ignore: deprecated_member_use
      barrierColor: AwColors.black.withOpacity(0.45),
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: AwColors.transparent,
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
              AwSpacing.s,
              AwText.normal(
                content,
                size: contentSize,
              ),
              AwSpacing.s12,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  WalletButton.textButton(
                    buttonText: okLabel,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              AwSpacing.s12,
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> showCardInfo(
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
      barrierColor: AwColors.black.withOpacity(0.45),
      builder: (ctx) {
        final textScale = MediaQuery.of(ctx).textScaleFactor;
        // Si el textScale es mayor a 1.2 (zoom activado), usar tamaños reducidos
        final adjustedTitleSize =
            textScale > 1.2 ? titleSize * 0.70 : titleSize;
        final adjustedContentSize =
            textScale > 1.2 ? contentSize * 0.70 : contentSize;
        final adjustedMaxWidth = textScale > 1.2 ? 340.0 : 520.0;

        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: AwColors.transparent,
          child: Material(
            color: AwColors.transparent,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                constraints:
                    BoxConstraints(minWidth: 200, maxWidth: adjustedMaxWidth),
                decoration: BoxDecoration(
                  color: AwColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AwColors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AwText.bold(
                            title,
                            color: titleColor ?? AwColors.appBarColor,
                            size: adjustedTitleSize,
                          ),
                          AwSpacing.s,
                          AwText.normal(content, size: adjustedContentSize),
                          AwSpacing.s12,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              WalletButton.textButton(
                                buttonText: okLabel,
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Material(
                        color: AwColors.transparent,
                        child: IconButton(
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<bool?> showConfirmCard(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Eliminar',
    String cancelLabel = 'Cancelar',
    Color? confirmColor,
    double titleSize = AwSize.s18,
    double contentSize = AwSize.s14,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AwColors.black.withOpacity(0.45),
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Material(
          color: AwColors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 520),
              decoration: BoxDecoration(
                color: AwColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AwColors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AwText.bold(
                          title,
                          color: AwColors.appBarColor,
                          size: titleSize,
                        ),
                        AwSpacing.s,
                        AwText.normal(content, size: contentSize),
                        AwSpacing.s12,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            WalletButton.textButton(
                              buttonText: cancelLabel,
                              onPressed: () => Navigator.of(ctx).pop(false),
                              alignment: MainAxisAlignment.end,
                            ),
                            AwSpacing.w12,
                            WalletButton.textButton(
                              buttonText: confirmLabel,
                              onPressed: () => Navigator.of(ctx).pop(true),
                              colorText: confirmColor ?? AwColors.appBarColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Material(
                      color: AwColors.transparent,
                      child: IconButton(
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
