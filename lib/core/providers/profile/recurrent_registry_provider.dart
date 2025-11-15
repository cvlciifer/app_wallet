import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/core/models/profile/recurrentes_state.dart';
import 'package:app_wallet/core/services/recurrent_registry_service.dart';

class RecurrentRegistryNotifier extends StateNotifier<RecurrentesState> {
  final RecurrentRegistryService _service;

  RecurrentRegistryNotifier([RecurrentRegistryService? service])
      : _service = service ?? RecurrentRegistryService(),
        super(const RecurrentesState()) {
    developer.log('RecurrentRegistryNotifier created',
        name: 'recurrent_registry_provider');
  }

  Future<void> loadRecurrents() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _service.getRecurrents();
      developer.log('loadRecurrents: loaded ${list.length}',
          name: 'recurrent_registry_provider');
      state = state.copyWith(items: list);
    } catch (e, st) {
      developer.log('loadRecurrents error: $e',
          error: e, stackTrace: st, name: 'recurrent_registry_provider');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<List<Map<String, dynamic>>> getRecurringItems(String id) async {
    try {
      developer.log('getRecurringItems for $id',
          name: 'recurrent_registry_provider');
      final rows = await _service.getRecurringItems(id);
      developer.log('getRecurringItems rows=${rows.length}',
          name: 'recurrent_registry_provider');
      return rows;
    } catch (e, st) {
      developer.log('getRecurringItems error: $e',
          error: e, stackTrace: st, name: 'recurrent_registry_provider');
      return [];
    }
  }

  Future<bool> updateRecurringItemAmount(
      String recurrenceId, int monthIndex, double newAmount) async {
    try {
      await _service.updateRecurringItemAmount(
          recurrenceId, monthIndex, newAmount);
      await loadRecurrents();
      return true;
    } catch (e, st) {
      developer.log('updateRecurringItemAmount error: $e',
          error: e, stackTrace: st, name: 'recurrent_registry_provider');
      return false;
    }
  }

  Future<bool> deleteRecurrenceFromMonth(
      String recurrenceId, int fromMonthIndex) async {
    try {
      await _service.deleteRecurrenceFromMonthLogged(
          recurrenceId, fromMonthIndex);
      await loadRecurrents();
      return true;
    } catch (e, st) {
      developer.log('deleteRecurrenceFromMonth error: $e',
          error: e, stackTrace: st, name: 'recurrent_registry_provider');
      return false;
    }
  }
}

final recurrentRegistryProvider =
    StateNotifierProvider<RecurrentRegistryNotifier, RecurrentesState>((ref) {
  return RecurrentRegistryNotifier();
});
