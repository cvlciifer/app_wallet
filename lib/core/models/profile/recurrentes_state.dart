import 'package:app_wallet/core/models/recurring_expense.dart';

class RecurrentesState {
  final List<RecurringExpense> items;
  final bool isLoading;
  final bool isSaving;

  const RecurrentesState({
    this.items = const [],
    this.isLoading = false,
    this.isSaving = false,
  });

  RecurrentesState copyWith({
    List<RecurringExpense>? items,
    bool? isLoading,
    bool? isSaving,
  }) {
    return RecurrentesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
