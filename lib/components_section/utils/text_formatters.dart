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

class MaxAmountFormatter extends TextInputFormatter {
  final int maxDigits;
  final int maxAmount;
  final VoidCallback? onAttemptOverLimit;

  static const int kEightDigits = 8;
  static const int kEightDigitsMaxAmount = 99999999;

  MaxAmountFormatter({this.maxDigits = kEightDigits, this.maxAmount = 90000000, this.onAttemptOverLimit});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = newValue.text.replaceAll(RegExp(r'\s+'), '');
    final newDigits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    final oldDigits = oldValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newDigits.length < oldDigits.length) {
      return newValue.copyWith(text: cleaned, selection: TextSelection.collapsed(offset: cleaned.length));
    }

    if (newDigits.length > maxDigits) {
      if (onAttemptOverLimit != null) onAttemptOverLimit!();
      return oldValue;
    }
    final n = int.tryParse(newDigits) ?? 0;
    if (n > maxAmount) {
      if (onAttemptOverLimit != null) onAttemptOverLimit!();
      return oldValue;
    }

    return newValue.copyWith(text: cleaned, selection: TextSelection.collapsed(offset: cleaned.length));
  }
}
