import 'package:app_wallet/home_section/presentation/new_expense/presentation/models/expense.dart';
import 'package:app_wallet/home_section/presentation/new_expense/presentation/models/category.dart';

class WalletExpenseBucket {
  const WalletExpenseBucket({
    required this.category,
    required this.expenses,
  });

  WalletExpenseBucket.forCategory(List<Expense> allExpenses, this.category)
      : expenses = allExpenses.where((expense) => expense.category == category).toList();

  final Category category;
  final List<Expense> expenses;

  double get totalExpenses {
    double sum = 0;
    for (final expense in expenses) {
      sum += expense.amount;
    }
    return sum;
  }
}
