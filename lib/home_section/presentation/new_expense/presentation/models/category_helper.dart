import 'package:flutter/material.dart';
import 'category.dart';

class WalletCategoryHelper {
  /// Devuelve icono según un identificador o nombre de categoría/subcategoría.
  static IconData getCategoryIcon(String categoryOrSubcategory) {
    // 1) buscar en subcategorías por id o por nombre
    for (final entry in subcategoriesByCategory.entries) {
      for (final sub in entry.value) {
        if (sub.id == categoryOrSubcategory || sub.name.toLowerCase() == categoryOrSubcategory.toLowerCase()) {
          return sub.icon;
        }
      }
    }

    // 2) buscar por nombre legible de la categoría
    for (final c in Category.values) {
      if (c.displayName.toLowerCase() == categoryOrSubcategory.toLowerCase() ||
          c.toString().split('.').last == categoryOrSubcategory) {
        return categoryIcons[c] ?? Icons.category;
      }
    }

    // fallback
    return Icons.category;
  }

  static Color getCategoryColor(String categoryOrSubcategory) {
    for (final c in Category.values) {
      if (c.displayName.toLowerCase() == categoryOrSubcategory.toLowerCase() ||
          c.toString().split('.').last == categoryOrSubcategory) {
        switch (c) {
          case Category.comidaBebida:
            return Colors.blue;
          case Category.comprasPersonales:
            return Colors.pink;
          case Category.salud:
            return Colors.green;
          case Category.hogarVivienda:
            return Colors.brown;
          case Category.transporte:
            return Colors.indigo;
          case Category.vehiculos:
            return Colors.orange;
          case Category.ocioEntretenimiento:
            return Colors.deepPurple;
          case Category.serviciosCuentas:
            return Colors.teal;
        }
      }
    }

    return Colors.grey;
  }
}
