import 'package:app_wallet/core/data_base_local/local_crud.dart';
import 'package:app_wallet/core/models/recurring_expense.dart';

class RecurrentRegistryService {
  final LocalCrud _local;

  RecurrentRegistryService([LocalCrud? local]) : _local = local ?? LocalCrud();

  Future<List<RecurringExpense>> getRecurrents() => _local.getRecurrents();

  Future<List<Map<String, dynamic>>> getRecurringItems(String id) =>
      _local.getRecurringItems(id);

  Future<void> updateRecurringItemAmount(
          String recurrenceId, int monthIndex, double newAmount) =>
      _local.updateRecurringItemAmount(recurrenceId, monthIndex, newAmount);

  Future<void> deleteRecurrenceFromMonth(
          String recurrenceId, int fromMonthIndex) =>
      _local.deleteRecurrenceFromMonth(recurrenceId, fromMonthIndex);
}
