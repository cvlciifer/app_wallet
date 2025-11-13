import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/core/models/recurring_expense.dart';
import 'package:app_wallet/home_section/presentation/new_expense/presentation/models/expense.dart';
import 'package:app_wallet/home_section/presentation/new_expense/presentation/models/category.dart';
import 'package:app_wallet/core/services/recurrent_create_service.dart';

class RecurrentCreateState {
  final bool isSubmitting;

  const RecurrentCreateState({this.isSubmitting = false});

  RecurrentCreateState copyWith({bool? isSubmitting}) =>
      RecurrentCreateState(isSubmitting: isSubmitting ?? this.isSubmitting);
}

class RecurrentCreateNotifier extends StateNotifier<RecurrentCreateState> {
  final RecurrentCreateService _service;

  RecurrentCreateNotifier([RecurrentCreateService? service])
      : _service = service ?? RecurrentCreateService(),
        super(const RecurrentCreateState()) {
    developer.log('RecurrentCreateNotifier created',
        name: 'recurrent_create_provider');
  }

  Future<bool> createRecurring(
      RecurringExpense recurring, List<Expense> generated) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true);
    try {
      await _service.insertRecurring(recurring, generated);
      developer.log('createRecurring: inserted recurrence ${recurring.id}',
          name: 'recurrent_create_provider');
      return true;
    } catch (e, st) {
      developer.log('createRecurring error: $e',
          error: e, stackTrace: st, name: 'recurrent_create_provider');
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

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
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true);
    try {
      final ok = await _service.createFromForm(
        title: title,
        amount: amount,
        dayOfMonth: dayOfMonth,
        months: months,
        startMonth: startMonth,
        startYear: startYear,
        category: category,
        subcategoryId: subcategoryId,
      );
      developer.log('createFromForm result: $ok',
          name: 'recurrent_create_provider');
      return ok;
    } catch (e, st) {
      developer.log('createFromForm error: $e',
          error: e, stackTrace: st, name: 'recurrent_create_provider');
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

final recurrentCreateProvider =
    StateNotifierProvider<RecurrentCreateNotifier, RecurrentCreateState>((ref) {
  return RecurrentCreateNotifier();
});
