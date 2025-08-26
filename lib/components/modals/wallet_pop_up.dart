import 'package:app_wallet/library/main_library.dart';
import 'package:flutter/material.dart';

class WalletPopup {
  WalletPopup._();

  static BuildContext? _context;

  static void showNotificationSuccess({
    required BuildContext context,
    required String title,
    Text? message,
    String? primaryButtonText,
    int? visibleTime,
    bool? isDismissible,
    VoidCallback? onPrimaryTap,
    bool showCloseButton = true,
    VoidCallback? onCloseTap,
  }) {
    showDialog(
      barrierDismissible: isDismissible ?? false,
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
                        color: AwColors.green,
                        width: AwSize.s4,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: AwSize.s12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.circle_outlined,
                              size: AwSize.s20,
                            ),
                            const SizedBox(width: AwSize.s10),
                            Expanded(
                              child: AwText.bold(title, color: AwColors.boldBlack),
                            ),
                            if (showCloseButton)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: AwSize.s12,
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
                        Padding(
                          padding: const EdgeInsets.only(left: AwSize.s30, right: AwSize.s30, bottom: AwSize.s10),
                          child: Column(
                            children: [
                              if (message != null) message,
                              if (showButton) const AwDivider(),
                              if (showButton)
                                WalletButton.primaryButton(
                                  buttonText: primaryButtonText,
                                  onPressed: () {
                                    if (onPrimaryTap != null) {
                                      onPrimaryTap();
                                    }
                                  },
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

  static void showNotificationWarning(
      {required BuildContext context,
      required String title,
      Text? message,
      String? primaryButtonText,
      int? visibleTime,
      bool? isDismissible,
      VoidCallback? onPrimaryTap}) {
    showDialog(
        barrierDismissible: isDismissible ?? false,
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
                      padding: const EdgeInsets.only(left: AwSize.s12, top: AwSize.s12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning,
                                // BciIcon.close,
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
                            padding: const EdgeInsets.only(left: AwSize.s30, right: AwSize.s30, bottom: AwSize.s10),
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
        });
  }

  static void showNotificationError({
    required BuildContext context,
    required String title,
    int? visibleTime,
    bool? isDismissible,
    bool showCloseButton = true, // Parámetro agregado
    VoidCallback? onCloseTap, // Para acción personalizada al cerrar
  }) {
    showDialog(
      barrierDismissible: isDismissible ?? false,
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
                    padding: const EdgeInsets.fromLTRB(AwSize.s12, AwSize.s12, 0, AwSize.s12),
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
                              child: AwText.bold(title, color: AwColors.boldBlack),
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

  static void setContext(BuildContext context) {
    _context = context;
  }

  static Future<void> popUpTimeClose(int visibleTime) async {
    await Future.delayed(Duration(seconds: visibleTime));
    closePopUp();
  }

  static void closePopUp() {
    if (_context != null && Navigator.canPop(_context!)) {
      Navigator.pop(_context!);
      _context = null;
    }
  }
}
