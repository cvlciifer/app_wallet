import 'package:app_wallet/library_section/main_library.dart';

/// Botón reutilizable con texto subrayado y estilo consistente con la app
class UnderlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  final Alignment alignment;

  const UnderlinedButton({
    Key? key,
    required this.text,
    required this.onTap,
    this.icon,
    this.color,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AwColors.appBarColor;

    final child = LayoutBuilder(builder: (context, constraints) {
      final hasBoundedWidth = constraints.maxWidth.isFinite;
      final maxTextWidth = hasBoundedWidth
          ? constraints.maxWidth
          : MediaQuery.of(context).size.width * 0.5;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: effectiveColor, size: 18),
            AwSpacing.w6,
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxTextWidth),
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AwSize.s14,
                fontWeight: FontWeight.bold,
                color: effectiveColor,
                decoration: TextDecoration.underline,
                decorationColor: effectiveColor,
                decorationThickness: 1.3,
              ),
            ),
          ),
        ],
      );
    });

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: child,
        ),
      ),
    );
  }
}
