import 'package:app_wallet/library/main_library.dart';

class AwText extends StatelessWidget {
  final String? text;
  final double? size;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final bool isDoubleText;
  final String? text2;
  final Color? colorText;
  final Color? colorText2;
  final TextOverflow? textOverflow;
  final int? maxLines;

  const AwText({
    super.key,
    required this.text,
    this.size = AwSize.medium,
    this.color = AwColors.black,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.isDoubleText = false,
    this.text2 = "",
    this.colorText = AwColors.black,
    this.colorText2 = AwColors.black,
    this.textOverflow = TextOverflow.visible,
    this.maxLines = 3,
  });

  /// Size: 8.0
  ///
  /// Color: [AwColors.black]
  ///
  /// FontWeight: 400
  ///
  const AwText.xxsmall(
    this.text, {
    super.key,
    this.size = AwSize.s8,
    this.color = AwColors.black,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.isDoubleText = false,
    this.text2 = "",
    this.colorText = AwColors.black,
    this.colorText2 = AwColors.black,
    this.textOverflow = TextOverflow.visible,
    this.maxLines = 3,
  });

  /// Size: 12.0
  ///
  /// Color: [AwColors.black]
  ///
  /// FontWeight: 400
  ///
  const AwText.xsmall(
    this.text, {
    super.key,
    this.size = AwSize.s12,
    this.color = AwColors.black,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.isDoubleText = false,
    this.text2 = "",
    this.colorText = AwColors.black,
    this.colorText2 = AwColors.black,
    this.textOverflow = TextOverflow.visible,
    this.maxLines = 3,
  });

  /// Size: 14.0
  ///
  /// Color: [AwColors.black]
  ///
  /// FontWeight: 400
  ///
  const AwText.small(
    this.text, {
    super.key,
    this.size = AwSize.small,
    this.color = AwColors.black,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.isDoubleText = false,
    this.text2 = "",
    this.colorText = AwColors.black,
    this.colorText2 = AwColors.black,
    this.textOverflow = TextOverflow.visible,
    this.maxLines = 3,
  });

  /// Size: 16.0
  ///
  /// Color: [AwColors.black]
  ///
  /// FontWeight: 400
  ///
  const AwText.normal(
    this.text, {
    super.key,
    this.size = AwSize.medium,
    this.color = AwColors.black,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.isDoubleText = false,
    this.text2 = "",
    this.colorText = AwColors.black,
    this.colorText2 = AwColors.black,
    this.textOverflow = TextOverflow.visible,
    this.maxLines = 3,
  });

  /// Size: 18.0
  ///
  /// Color: [AwColors.black]
  ///
  /// FontWeight: 400
  ///
  const AwText.large(
    this.text, {
    super.key,
    this.size = AwSize.large,
    this.color = AwColors.black,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.isDoubleText = false,
    this.text2 = "",
    this.colorText = AwColors.black,
    this.colorText2 = AwColors.black,
    this.textOverflow = TextOverflow.visible,
    this.maxLines = 3,
  });

  /// Size: 12.0
  ///
  /// Color: [AwColors.black]
  ///
  /// FontWeight: 400
  ///
  const AwText.xlarge(
    this.text, {
    super.key,
    this.size = AwSize.s22,
    this.color = AwColors.black,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.isDoubleText = false,
    this.text2 = "",
    this.colorText = AwColors.black,
    this.colorText2 = AwColors.black,
    this.textOverflow = TextOverflow.visible,
    this.maxLines = 3,
  });

  /// Size: 16.0
  ///
  /// Color: [AwColors.black]
  ///
  /// FontWeight: 700
  ///
  const AwText.bold(
    this.text, {
    super.key,
    this.size = AwSize.medium,
    this.color = AwColors.black,
    this.fontWeight = FontWeight.w700,
    this.textAlign = TextAlign.left,
    this.isDoubleText = false,
    this.text2 = "",
    this.colorText = AwColors.black,
    this.colorText2 = AwColors.black,
    this.textOverflow = TextOverflow.visible,
    this.maxLines = 3,
  });

  /// Size: 16.0
  ///
  /// Color: [AwColors.black]
  ///
  /// FontWeight: 700
  ///
  const AwText.multiStyle(
    this.text, {
    super.key,
    this.size = AwSize.medium,
    this.color = AwColors.black,
    this.fontWeight = FontWeight.w700,
    this.textAlign = TextAlign.left,
    this.isDoubleText = true,
    this.text2 = "",
    this.colorText = AwColors.black,
    this.colorText2 = AwColors.black,
    this.textOverflow = TextOverflow.visible,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (isDoubleText) {
      return Text.rich(
        TextSpan(
          text: '',
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: text!,
              style: TextStyle(
                fontSize: size,
                fontWeight: fontWeight,
                color: colorText,
              ),
            ),
            TextSpan(
              text: text2,
              style: TextStyle(
                fontSize: size,
                fontWeight: fontWeight,
                color: colorText2,
              ),
            ),
          ],
        ),
      );
    } else {
      return Text(
        text!,
        textAlign: textAlign,
        overflow: textOverflow,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: fontWeight,
        ),
        maxLines: maxLines,
      );
    }
  }
}
