import 'package:app_wallet/library_section/main_library.dart';

class FormHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double? titleSize;
  final Color? titleColor;
  final double? subtitleSize;
  final Color? subtitleColor;

  const FormHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.titleSize,
    this.titleColor,
    this.subtitleSize,
    this.subtitleColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AwText.bold(
          title,
          size: titleSize ?? AwSize.s20,
          color: titleColor ?? AwColors.boldBlack,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          AwText(
            text: subtitle!,
            color: subtitleColor ?? AwColors.blueGrey,
            size: subtitleSize ?? AwSize.s14,
          ),
        ],
      ],
    );
  }
}
