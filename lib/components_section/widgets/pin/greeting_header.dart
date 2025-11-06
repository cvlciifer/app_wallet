import 'package:app_wallet/library_section/main_library.dart';

class GreetingHeader extends StatelessWidget {
  final String? alias;

  const GreetingHeader({Key? key, this.alias}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text =
        (alias != null && alias!.isNotEmpty) ? 'Hola ${alias!}...' : 'Hola...';
    return Align(
      alignment: Alignment.centerLeft,
      child: AwText.bold(
        text,
        size: AwSize.s30,
        color: AwColors.appBarColor,
      ),
    );
  }
}
