import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'package:app_wallet/core/data_base_local/local_crud.dart';
import 'package:app_wallet/core/models/recurring_expense.dart';
import 'package:app_wallet/home_section/presentation/new_expense/presentation/models/expense.dart';
import 'package:app_wallet/home_section/presentation/new_expense/presentation/models/category.dart';
import 'package:app_wallet/core/sync_service/sync_service.dart';

class RecurrentCreateService {
  final LocalCrud _local;

  RecurrentCreateService([LocalCrud? local]) : _local = local ?? LocalCrud();

  Future<void> insertRecurring(
          RecurringExpense recurring, List<Expense> generated) =>
      _local.insertRecurring(recurring, generated);

  Future<bool> createFromForm({
    required String title,
    required double amount,
    required int dayOfMonth,
    required int months,
    required int startMonth,
    required int startYear,
    required Category category,
    String? subcategoryId,
  }) async {
    // Basic validation
    if (months < 1 || amount <= 0) return false;

    final recurrenceId = const Uuid().v4();
    final generated = <Expense>[];
    for (var i = 0; i < months; i++) {
      final monthDate = DateTime(startYear, startMonth + i);
      final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0).day;
      final actualDay = math.min(dayOfMonth, lastDay);
      final dt = DateTime(monthDate.year, monthDate.month, actualDay);
      final expenseId = '$recurrenceId-${i + 1}';
      final e = Expense(
        id: expenseId,
        title: title,
        amount: amount,
        date: dt,
        category: category,
        subcategoryId: subcategoryId,
        syncStatus: SyncStatus.pendingCreate,
        recurrenceId: recurrenceId,
        recurrenceIndex: i + 1,
      );
      generated.add(e);
    }

    final recurring = RecurringExpense(
      id: recurrenceId,
      title: title,
      amount: amount,
      dayOfMonth: dayOfMonth,
      months: months,
      startYear: startYear,
      startMonth: startMonth,
      category: category,
      subcategoryId: subcategoryId,
    );

    await insertRecurring(recurring, generated);
    return true;
  }
}
