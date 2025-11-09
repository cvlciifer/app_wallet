// método de capitalización - para que la primera letra del texto sea mayúscula, la puse acá para uso global
extension StringCapitalizationExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
