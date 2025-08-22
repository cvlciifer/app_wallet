import 'package:app_wallet/library/main_library.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final String? prefixText;
  final bool hideCounter;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.prefixText,
    this.hideCounter = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          label: Text(label),
          prefixText: prefixText,
          counterText: hideCounter ? '' : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AwColors.appBarColor),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
