import 'package:app_wallet/library_section/main_library.dart';

class CompactActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool primary;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const CompactActionButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.primary = false,
    this.height = 32.0,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return SizedBox(
        height: height,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AwColors.indigo,
            minimumSize: Size.fromHeight(height),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: AwText.bold(
            text,
            size: AwSize.s14,
            color: textColor ?? AwColors.white,
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor ?? AwColors.indigoInk),
          minimumSize: Size.fromHeight(height),
          backgroundColor:
              // ignore: deprecated_member_use
              backgroundColor ?? AwColors.indigoInk.withOpacity(0.65),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: AwText.bold(
          text,
          size: AwSize.s14,
          color: textColor ?? AwColors.white,
        ),
      ),
    );
  }
}
