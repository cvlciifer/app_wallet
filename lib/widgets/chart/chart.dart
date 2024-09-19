import 'package:flutter/material.dart';
import 'package:app_wallet/models/expense.dart';
import 'package:app_wallet/widgets/chart/chart_bar.dart';

/* class Chart extends StatelessWidget {
  const Chart({super.key, required this.expenses});

  final List<Expense> expenses;

  List<ExpenseBucket> get buckets {
    return [
      ExpenseBucket.forCategory(expenses, Category.comida),
      ExpenseBucket.forCategory(expenses, Category.ocio),
      ExpenseBucket.forCategory(expenses, Category.viajes),
      ExpenseBucket.forCategory(expenses, Category.trabajo),
      ExpenseBucket.forCategory(expenses, Category.categoria),
    ];
  }

  double get maxTotalExpense {
    double maxTotalExpense = 0;

    for (final bucket in buckets) {
      if (bucket.totalExpenses > maxTotalExpense) {
        maxTotalExpense = bucket.totalExpenses;
      }
    }

    return maxTotalExpense;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 8,
      ),
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFCEE4F2), // Background color from your palette
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buckets.map((bucket) {
                return ChartBar(
                  fill: bucket.totalExpenses == 0
                      ? 0
                      : bucket.totalExpenses / maxTotalExpense,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: buckets.map((bucket) {
              return Icon(
                categoryIcons[bucket.category],
                color: const Color(0xFF03738C), // Icon color from your palette
                size: 18,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
 */
class Chart extends StatelessWidget {
  const Chart({super.key, required this.expenses});

  final List<Expense> expenses;

  List<ExpenseBucket> get buckets {
    return [
      ExpenseBucket.forCategory(expenses, Category.comida),
      ExpenseBucket.forCategory(expenses, Category.ocio),
      ExpenseBucket.forCategory(expenses, Category.viajes),
      ExpenseBucket.forCategory(expenses, Category.trabajo),
      ExpenseBucket.forCategory(expenses, Category.categoria),
    ];
  }

  double get maxTotalExpense {
    double maxTotalExpense = 0;

    for (final bucket in buckets) {
      if (bucket.totalExpenses > maxTotalExpense) {
        maxTotalExpense = bucket.totalExpenses;
      }
    }

    return maxTotalExpense;
  }

  // Función que asigna un color basado en la categoría
  Color getColorForCategory(Category category) {
    switch (category) {
      case Category.comida:
        return Color(0xFFCEE4F2); // Color para comida
      case Category.ocio:
        return Color(0xFF011C26); // Color para ocio
      case Category.viajes:
        return Color(0xFF88B0BF); // Color para viajes
      case Category.trabajo:
        return Color(0xFF03738C); // Color para trabajo
      default:
        return Colors.teal; // Color para la categoría general
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 8,
      ),
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFCEE4F2), // Fondo
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buckets.map((bucket) {
                return ChartBar(
                  fill: bucket.totalExpenses == 0
                      ? 0
                      : bucket.totalExpenses / maxTotalExpense,
                  barColor: getColorForCategory(bucket.category), // Color específico
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: buckets.map((bucket) {
              return Icon(
                categoryIcons[bucket.category],
                color: const Color(0xFF03738C), // Color para los íconos
                size: 22,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
