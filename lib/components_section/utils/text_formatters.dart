import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Formateador de entrada personalizado
class CustomLengthTextInputFormatter extends TextInputFormatter {
  final int maxLength;

  CustomLengthTextInputFormatter(this.maxLength);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Comprueba la longitud del nuevo valor
    if (newValue.text.length > maxLength) {
      // Si es mayor que el límite, devuelve el valor antiguo
      return oldValue;
    }
    return newValue;
  }
}

/// Formateador para CLP: inserta separadores de miles (puntos) mientras se escribe.
class CLPTextInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('es_CL');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Extraer sólo dígitos
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    // Evitar números muy largos que exploten la parse
    final capped = digits.length > 15 ? digits.substring(0, 15) : digits;

    final number = int.parse(capped);
    final newText = _formatter.format(number);

    // Mantener el cursor al final (simple y estable)
    return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}
