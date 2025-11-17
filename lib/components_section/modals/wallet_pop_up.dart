import 'package:app_wallet/library_section/main_library.dart';

class WalletPopup {
  WalletPopup._();

  static BuildContext? _context;

  static void showNotificationSuccess({
    required BuildContext context,
    required String title,
    Widget? message,
    String? primaryButtonText,
    int visibleTime = 2,
    bool? isDismissible,
    VoidCallback? onPrimaryTap,
    bool showCloseButton = false,
    VoidCallback? onCloseTap,
  }) {
    showDialog(
      useRootNavigator: true,
      barrierDismissible: isDismissible ?? true,
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        setContext(context);
        popUpTimeClose(visibleTime);
        return Stack(
          children: [
            Positioned(
              top: AwSize.s64,
              left: AwSize.s18,
              right: AwSize.s18,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () => closePopUp(),
                  onHorizontalDragEnd: (_) => closePopUp(),
                  onVerticalDragEnd: (_) => closePopUp(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: AwSize.s12, horizontal: AwSize.s16),
                    decoration: BoxDecoration(
                      color: AwColors.green,
                      borderRadius: BorderRadius.circular(AwSize.s6),
                      boxShadow: [
                        BoxShadow(
                          color: AwColors.grey.withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AwColors.white,
                          size: AwSize.s20,
                        ),
                        const SizedBox(width: AwSize.s10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AwText.bold(title, color: AwColors.white),
                              if (message != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: AwSize.s4),
                                  child: message,
                                ),
                            ],
                          ),
                        ),
                        // No close button for success popup; it auto-closes.
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showNotificationWarningOrange({
    required BuildContext context,
    required String message,
    int visibleTime = 2,
    bool isDismissible = true,
  }) {
    showDialog(
      useRootNavigator: true,
      barrierDismissible: isDismissible,
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        setContext(context);
        popUpTimeClose(visibleTime);
        return Stack(
          children: [
            Positioned(
              top: AwSize.s64,
              left: AwSize.s18,
              right: AwSize.s18,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () => closePopUp(),
                  onHorizontalDragEnd: (_) => closePopUp(),
                  onVerticalDragEnd: (_) => closePopUp(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: AwSize.s12, horizontal: AwSize.s16),
                    decoration: BoxDecoration(
                      color: AwColors.orangeDark,
                      borderRadius: BorderRadius.circular(AwSize.s6),
                      boxShadow: [
                        BoxShadow(
                          color: AwColors.grey.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: AwSize.s34,
                          height: AwSize.s34,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.warning,
                              color: AwColors.orangeDark,
                              size: AwSize.s18,
                            ),
                          ),
                        ),
                        const SizedBox(width: AwSize.s12),
                        Expanded(
                          child: AwText.normal(
                            message,
                            color: AwColors.white,
                            size: AwSize.s14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showNotificationError({
    required BuildContext context,
    required String title,
    int? visibleTime,
    bool? isDismissible,
    bool showCloseButton = false,
    VoidCallback? onCloseTap,
  }) {
    showDialog(
      useRootNavigator: true,
      barrierDismissible: isDismissible ?? true,
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        setContext(context);
        popUpTimeClose(visibleTime ?? 2);
        return Stack(
          children: [
            Positioned(
              top: AwSize.s64,
              left: AwSize.s18,
              right: AwSize.s18,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {
                    if (onCloseTap != null) onCloseTap();
                    closePopUp();
                  },
                  onHorizontalDragEnd: (_) {
                    if (onCloseTap != null) onCloseTap();
                    closePopUp();
                  },
                  onVerticalDragEnd: (_) {
                    if (onCloseTap != null) onCloseTap();
                    closePopUp();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: AwSize.s12, horizontal: AwSize.s16),
                    decoration: BoxDecoration(
                      color: AwColors.red,
                      borderRadius: BorderRadius.circular(AwSize.s6),
                      boxShadow: [
                        BoxShadow(
                          color: AwColors.grey.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error,
                          color: AwColors.white,
                          size: AwSize.s20,
                        ),
                        const SizedBox(width: AwSize.s10),
                        Expanded(
                          child: AwText.bold(
                            title,
                            color: AwColors.white,
                            size: AwSize.s14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showAttentionBanner({
    required BuildContext context,
    required String message,
    Color? backgroundColor,
    int? visibleTime,
    bool? isDismissible,
  }) {
    showDialog(
      useRootNavigator: true,
      barrierDismissible: isDismissible ?? true,
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        setContext(context);
        popUpTimeClose(visibleTime ?? 2);
        return Stack(
          children: [
            Positioned(
              top: AwSize.s64,
              left: AwSize.s18,
              right: AwSize.s18,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () => closePopUp(),
                  onHorizontalDragEnd: (_) => closePopUp(),
                  onVerticalDragEnd: (_) => closePopUp(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: AwSize.s12, horizontal: AwSize.s16),
                    decoration: BoxDecoration(
                      color: backgroundColor ?? AwColors.appBarColor,
                      borderRadius: BorderRadius.circular(AwSize.s6),
                      boxShadow: [
                        BoxShadow(
                          color: AwColors.grey.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: AwText.normal(
                            message,
                            color: AwColors.white,
                            size: AwSize.s14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void setContext(BuildContext context) {
    _context = context;
  }

  static Future<void> popUpTimeClose(int visibleTime) async {
    await Future.delayed(Duration(seconds: visibleTime));
    closePopUp();
  }

  static void closePopUp() {
    if (_context == null) return;
    try {
      if (_context is Element && !(_context as Element).mounted) {
        _context = null;
        return;
      }
    } catch (_) {
      // ignore
    }
    try {
      if (Navigator.canPop(_context!)) {
        Navigator.pop(_context!);
      }
    } catch (_) {
      // ignore errors when navigator not available
    }
    _context = null;
  }
}
