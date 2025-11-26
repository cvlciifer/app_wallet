import 'package:flutter/gestures.dart';
import 'package:app_wallet/library_section/main_library.dart';

class WalletButton {
  static Widget primaryButton({
    required String buttonText,
    required Function()? onPressed,
    double? height = AwSize.s48,
    Color? backgroundColor = AwColors.appBarColor,
    Color? buttonTextColor = AwColors.white,
  }) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AwSize.s16,
            ),
          ),
        ),
        child: Center(
          child: AwText.bold(
            buttonText,
            color: buttonTextColor,
            size: AwSize.s14,
          ),
        ),
      ),
    );
  }

  static Widget secondaryButton({
    required String buttonText,
    required Function()? onPressed,
  }) {
    return SizedBox(
      height: AwSize.s48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: AwColors.blue,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AwSize.s16,
            ),
          ),
        ),
        child: Center(
          child: AwText.bold(
            buttonText,
            size: AwSize.s14,
            color: AwColors.blue,
          ),
        ),
      ),
    );
  }

  static Widget textButton({
    required String buttonText,
    required Function()? onPressed,
    MainAxisAlignment? alignment,
    Color colorText = AwColors.blue,
    double fontSize = AwSize.s16,
  }) {
    return Row(
      mainAxisAlignment: alignment ?? MainAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: colorText,
                decorationColor: colorText,
                decorationThickness: 1,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: buttonText,
                  recognizer: TapGestureRecognizer()..onTap = onPressed,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget iconButtonText({
    required String buttonText,
    required Function() onPressed,
    double? height = AwSize.s48,
    IconData? icon,
    Color backgroundColor = AwColors.blueGrey,
    Color iconColor = AwColors.white,
    double iconSize = 24.0,
    double fontSize = AwSize.s14,
    FontWeight fontWeight = FontWeight.bold,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  }) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AwSize.s16,
            ),
          ),
          padding: padding,
        ),
        child: Center(
          child: icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: iconColor,
                      size: iconSize,
                    ),
                    AwSpacing.w,
                    AwText.bold(
                      buttonText,
                      color: AwColors.white,
                      size: fontSize,
                    ),
                  ],
                )
              : AwText.bold(
                  buttonText,
                  color: AwColors.white,
                  size: fontSize,
                ),
        ),
      ),
    );
  }

  static Widget filterButton({
    required String buttonText,
    required Function() onPressed,
    MainAxisAlignment? alignment,
    Color colorText = AwColors.appBarColor,
    bool selected = false,
  }) {
    return Row(
      mainAxisAlignment: alignment ?? MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.only(bottom: selected ? 0.5 : 0.0),
            decoration: selected
                ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorText,
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                  )
                : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: AutoSizeText(
                buttonText,
                style: TextStyle(
                  fontSize: AwSize.s14,
                  fontWeight: FontWeight.bold,
                  color: colorText,
                  letterSpacing: 1.2,
                ),
                maxLines: 1,
                minFontSize: 10,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
