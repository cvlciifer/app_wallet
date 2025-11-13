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
  final bool flat;

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
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final InputBorder effectiveBorder = flat
        ? UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          );

    return SizedBox(
      height: 75,
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        textAlign: textAlign ?? TextAlign.start,
        textAlignVertical: textAlignVertical,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          prefixText: prefixText,
          counterText: hideCounter ? '' : null,
          border: effectiveBorder,
          enabledBorder: effectiveBorder,
          focusedBorder: flat
              ? const UnderlineInputBorder(borderSide: BorderSide(color: AwColors.appBarColor))
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AwColors.appBarColor),
                ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: flat ? 18 : 18,
          ),
        ),
      ),
    );
  }
}
