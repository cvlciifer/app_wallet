import 'package:app_wallet/library_section/main_library.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final String? prefixText;
  final bool hideCounter;
  final TextAlign? textAlign;
  final TextAlignVertical? textAlignVertical;

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
    this.textAlign,
    this.textAlignVertical,
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
        textAlign: textAlign ?? TextAlign.start,
        textAlignVertical: textAlignVertical,
        decoration: InputDecoration(
          label: AwText(
            text: label,
            color: AwColors.black,
          ),
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
