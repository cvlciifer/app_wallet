import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter/material.dart';

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
      barrierDismissible: isDismissible ?? false,
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
          ],
        );
      },
    );
  }

  static void showNotificationWarning({
    required BuildContext context,
    required String title,
    Widget? message,
    String? primaryButtonText,
    int? visibleTime,
    bool? isDismissible,
    VoidCallback? onPrimaryTap,
  }) {
    showDialog(
      useRootNavigator: true,
      barrierDismissible: isDismissible ?? false,
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        bool showButton = primaryButtonText != null;
        setContext(context);
        if (visibleTime != null) {
          popUpTimeClose(visibleTime);
        }
        return Stack(
          children: [
            Positioned(
              top: AwSize.s64,
              left: AwSize.s18,
              right: AwSize.s18,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: AwColors.white,
                    borderRadius: BorderRadius.circular(AwSize.s4),
                    border: const Border(
                      left: BorderSide(
                        color: AwColors.yellow,
                        width: AwSize.s4,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: AwSize.s12, top: AwSize.s12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              size: AwSize.s20,
                            ),
                            const SizedBox(width: AwSize.s10),
                            Expanded(
                              child: AwText.bold(
                                title,
                                color: AwColors.boldBlack,
                                size: AwSize.s14,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: AwSize.s12,
                                color: AwColors.grey,
                              ),
                              onPressed: () {
                                closePopUp();
                              },
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: AwSize.s30,
                              right: AwSize.s30,
                              bottom: AwSize.s10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message != null) message,
                              if (showButton) const AwDivider(),
                              if (showButton)
                                SizedBox(
                                  width: 150,
                                  child: WalletButton.textButton(
                                    buttonText: primaryButtonText,
                                    onPressed: () {
                                      if (onPrimaryTap != null) {
                                        onPrimaryTap();
                                      }
                                    },
                                  ),
                                ),
                              if (showButton) AwSpacing.m
                            ],
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

  /// Warning style orange banner (resembling the provided image)
  static void showNotificationWarningOrange({
    required BuildContext context,
    required String message,
    int visibleTime = 3,
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: AwSize.s12, horizontal: AwSize.s16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF57C00),
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
                            color: Color(0xFFF57C00),
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
    bool showCloseButton = true,
    VoidCallback? onCloseTap,
  }) {
    showDialog(
      useRootNavigator: true,
      barrierDismissible: isDismissible ?? false,
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        setContext(context);
        if (visibleTime != null) {
          popUpTimeClose(visibleTime);
        }
        return Stack(
          children: [
            Positioned(
              top: AwSize.s64,
              left: AwSize.s18,
              right: AwSize.s18,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: AwColors.white,
                    borderRadius: BorderRadius.circular(AwSize.s4),
                    border: const Border(
                      left: BorderSide(
                        color: AwColors.red,
                        width: AwSize.s4,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AwSize.s12, AwSize.s12, 0, AwSize.s12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: AwColors.red,
                              size: AwSize.s20,
                            ),
                            const SizedBox(width: AwSize.s10),
                            Expanded(
                              child:
                                  AwText.bold(title, color: AwColors.boldBlack),
                            ),
                            if (showCloseButton)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AwColors.grey,
                                ),
                                onPressed: () {
                                  if (onCloseTap != null) {
                                    onCloseTap();
                                  } else {
                                    closePopUp();
                                  }
                                },
                              ),
                          ],
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
      barrierDismissible: isDismissible ?? false,
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        setContext(context);
        if (visibleTime != null) {
          popUpTimeClose(visibleTime);
        }
        return Stack(
          children: [
            Positioned(
              top: AwSize.s64,
              left: AwSize.s18,
              right: AwSize.s18,
              child: Material(
                color: Colors.transparent,
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
                      const SizedBox(width: AwSize.s8),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AwColors.white,
                          size: AwSize.s16,
                        ),
                        onPressed: () {
                          closePopUp();
                        },
                      ),
                    ],
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
