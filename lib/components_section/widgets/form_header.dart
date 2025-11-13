import 'package:app_wallet/library_section/main_library.dart';

class FormHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const FormHeader({Key? key, required this.title, this.subtitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AwText.bold(title, size: 20),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          AwText(text: subtitle!, color: AwColors.blueGrey),
        ],
      ],
    );
  }
}
