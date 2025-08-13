
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:app_wallet/models/category.dart';

final formatter = DateFormat.yMd();
const uuid = Uuid();

class Expense {
  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  }) : id = uuid.v4();

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;

  String get formattedDate {
    return formatter.format(date);
  }
}
 