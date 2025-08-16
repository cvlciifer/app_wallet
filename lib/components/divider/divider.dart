import 'package:app_wallet/library/main_library.dart';

class AwDivider extends StatelessWidget {
  final Color color;
  final EdgeInsetsGeometry margin;

  const AwDivider({
    Key? key,
    this.color =  AwColors.greyLight,
    this.margin = const EdgeInsets.only(top: 18, bottom: 18),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Divider(
        color: color,
        thickness: 1,
        height: 1,
      ),
    );
  }
}