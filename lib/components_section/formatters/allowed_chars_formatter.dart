import 'package:flutter/services.dart';

class AllowedCharsFormatter extends TextInputFormatter {
  final RegExp allowedChar;
  final VoidCallback? onBlocked;

  AllowedCharsFormatter({required this.allowedChar, this.onBlocked});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final buffer = StringBuffer();
    var blocked = false;

    int utf16Pos = 0;
    int allowedBeforeCursor = 0;
    final int originalCursor =
        newValue.selection.baseOffset.clamp(0, newValue.text.length);

    for (final r in newValue.text.runes) {
      final ch = String.fromCharCode(r);
      final int chUtf16Len = ch.length;
      final bool runeStartsBeforeCursor = utf16Pos < originalCursor;

      if (allowedChar.hasMatch(ch)) {
        buffer.write(ch);
        if (runeStartsBeforeCursor) allowedBeforeCursor++;
      } else {
        blocked = true;
      }

      utf16Pos += chUtf16Len;
    }

    final filtered = buffer.toString();
    if (blocked && onBlocked != null) onBlocked!();

    final int selectionIndex = allowedBeforeCursor.clamp(0, filtered.length);

    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
