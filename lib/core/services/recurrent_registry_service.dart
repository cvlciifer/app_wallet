import 'dart:developer' as developer;

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

    Future<void> deleteRecurrenceSingleMonth(
                    String recurrenceId, int monthIndex) =>
            _local.deleteRecurrenceSingleMonth(recurrenceId, monthIndex);

    Future<void> deleteRecurrenceFromMonthLogged(
            String recurrenceId, int fromMonthIndex) async {
        developer.log('service.deleteRecurrenceFromMonth called',
                name: 'recurrent_registry_service',
                error: {'recurrenceId': recurrenceId, 'fromMonthIndex': fromMonthIndex});
        try {
            await _local.deleteRecurrenceFromMonth(recurrenceId, fromMonthIndex);
            developer.log('service.deleteRecurrenceFromMonth completed',
                    name: 'recurrent_registry_service');
        } catch (e, st) {
            developer.log('service.deleteRecurrenceFromMonth threw',
                    name: 'recurrent_registry_service', error: '$e\n$st');
            rethrow;
        }
    }

        Future<void> deleteRecurrenceSingleMonthLogged(
                String recurrenceId, int monthIndex) async {
            developer.log('service.deleteRecurrenceSingleMonth called',
                    name: 'recurrent_registry_service',
                    error: {'recurrenceId': recurrenceId, 'monthIndex': monthIndex});
            try {
                await _local.deleteRecurrenceSingleMonth(recurrenceId, monthIndex);
                developer.log('service.deleteRecurrenceSingleMonth completed',
                        name: 'recurrent_registry_service');
            } catch (e, st) {
                developer.log('service.deleteRecurrenceSingleMonth threw',
                        name: 'recurrent_registry_service', error: '$e\n$st');
                rethrow;
            }
        }
}
