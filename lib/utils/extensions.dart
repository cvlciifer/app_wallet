// método de capitalización - para que la primera letra del texto sea mayúscula, la puse acá para uso global
// (si no se podria quitar y dejar en detail_expense_content.dart, que fuen en donde la utilice.)
extension StringCapitalizationExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
