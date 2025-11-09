import 'package:app_wallet/library_section/main_library.dart';

class SettingsCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AwColors.grey.withOpacity(0.08)),
      ),
      child: ListTile(
        minLeadingWidth: 40,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        leading: Icon(icon, color: AwColors.grey, size: iconSize),
        title: AwText.normal(
          title,
          color: AwColors.black,
          size: AwSize.s16,
          fontWeight: titleWeight,
        ),
        subtitle: subtitle != null
            ? AwText.small(subtitle!, color: AwColors.grey)
            : null,
        trailing: trailing ??
            Icon(Icons.chevron_right, color: AwColors.blue, size: 28),
      ),
    );
  }
}
