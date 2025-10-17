import 'package:flutter/services.dart';

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
