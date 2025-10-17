import 'package:flutter/material.dart';

class WalletCategoryHelper {
  static const Map<String, IconData> categoryIcons = {
    'comida': Icons.lunch_dining,
    'viajes': Icons.flight_takeoff,
    'ocio': Icons.movie,
    'trabajo': Icons.work,
    'salud': Icons.health_and_safety,
    'servicios': Icons.design_services,
  };

  static IconData getCategoryIcon(String category) {
    return categoryIcons[category] ?? Icons.category;
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'comida':
        return Colors.blue;
      case 'viajes':
        return Colors.red;
      case 'ocio':
        return Colors.green;
      case 'trabajo':
        return Colors.orange;
      case 'salud':
        return Colors.purple;
      case 'servicios':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}