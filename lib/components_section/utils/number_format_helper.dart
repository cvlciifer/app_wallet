import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/components_section/utils/text_formatters.dart' as formatters;

class NumberFormatHelper {
  static String formatAmount(
    String value,
  ) {
    if (value.isEmpty) return '';

    final numericValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (numericValue.isEmpty) return '';

    final number = int.parse(numericValue);
    final formatter = NumberFormat('#,###', 'es_ES');

    return formatter.format(number);
  }

  static List<TextInputFormatter> getAmountFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      formatters.CustomLengthTextInputFormatter(12),
    ];
  }
}
