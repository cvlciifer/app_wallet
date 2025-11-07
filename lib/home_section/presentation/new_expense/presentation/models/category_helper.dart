import 'package:flutter/material.dart';
import 'category.dart';

class WalletCategoryHelper {
  static IconData getCategoryIcon(String categoryOrSubcategory) {
    for (final entry in subcategoriesByCategory.entries) {
      for (final sub in entry.value) {
        if (sub.id == categoryOrSubcategory || sub.name.toLowerCase() == categoryOrSubcategory.toLowerCase()) {
          return sub.icon;
        }
      }
    }

    for (final c in Category.values) {
      if (c.displayName.toLowerCase() == categoryOrSubcategory.toLowerCase() ||
          c.toString().split('.').last == categoryOrSubcategory) {
        return categoryIcons[c] ?? Icons.category;
      }
    }

    return Icons.category;
  }

  static Color getCategoryColor(String categoryOrSubcategory) {
    for (final c in Category.values) {
      if (c.displayName.toLowerCase() == categoryOrSubcategory.toLowerCase() ||
          c.toString().split('.').last == categoryOrSubcategory) {
        return c.color;
      }
    }

    return Colors.grey;
  }
}
