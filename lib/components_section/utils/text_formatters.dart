import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CustomLengthTextInputFormatter extends TextInputFormatter {
  final int maxLength;

  CustomLengthTextInputFormatter(this.maxLength);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length > maxLength) {
      return oldValue;
    }
    return newValue;
  }
}

class CLPTextInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('es_CL');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final capped = digits.length > 15 ? digits.substring(0, 15) : digits;

    final number = int.parse(capped);
    final newText = _formatter.format(number);

    return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}
