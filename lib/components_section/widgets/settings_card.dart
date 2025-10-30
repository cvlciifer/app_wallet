import 'package:app_wallet/library_section/main_library.dart';

class SettingsCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? subtitle;
  final double iconSize;
  final FontWeight titleWeight;

  const SettingsCard({
    Key? key,
    required this.title,
    required this.icon,
    this.onTap,
    this.trailing,
    this.subtitle,
    this.iconSize = 26.0,
    this.titleWeight = FontWeight.w500,
  }) : super(key: key);

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (mounted) setState(() => _pressed = v);
  }

  void _handleTap() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        _handleTap();
      },
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _pressed
                ? AwColors.grey.withOpacity(0.05)
                : Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AwColors.grey.withOpacity(0.08)),
          ),
          child: ListTile(
            minLeadingWidth: 40,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            leading:
                Icon(widget.icon, color: AwColors.grey, size: widget.iconSize),
            title: AwText.normal(
              widget.title,
              color: AwColors.black,
              size: AwSize.s16,
              fontWeight: widget.titleWeight,
            ),
            subtitle: widget.subtitle != null
                ? AwText.small(widget.subtitle!, color: AwColors.grey)
                : null,
            trailing: widget.trailing ??
                const Icon(Icons.chevron_right, color: AwColors.blue, size: 28),
          ),
        ),
      ),
    );
  }
}
