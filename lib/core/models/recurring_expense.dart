import 'package:app_wallet/library_section/main_library.dart';

class RecurringExpense {
  final String id; // generated uuid for recurrence
  final String title;
  final double amount;
  final int dayOfMonth;
  final int months; // duration in months
  final int startYear;
  final int startMonth;
  final Category category;
  final String? subcategoryId;

  RecurringExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.dayOfMonth,
    required this.months,
    required this.startYear,
    required this.startMonth,
    required this.category,
    this.subcategoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dayOfMonth': dayOfMonth,
      'months': months,
      'startYear': startYear,
      'startMonth': startMonth,
      'category': category.toString().split('.').last,
      'subcategoryId': subcategoryId,
    };
  }
}
