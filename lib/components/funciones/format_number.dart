import 'package:app_wallet/Library/main_library.dart';

// Formateador para los números con '.' cada tres dígitos
String formatNumber(double value) {
  final formatter = NumberFormat('#,##0', 'es');
  return '\$${formatter.format(value)}'; // Añade el símbolo $
}
