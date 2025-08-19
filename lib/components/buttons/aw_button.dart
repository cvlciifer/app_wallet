import 'package:app_wallet/Library/main_library.dart';

class AwButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool bold;

  const AwButton({
    required this.label,
    required this.onPressed,
    this.color = AwColors.blue,
    this.bold = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
        ),
        child: AwText.bold(label, color: color));
  }
}
