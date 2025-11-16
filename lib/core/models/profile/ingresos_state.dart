class IngresosState {
  final int months;
  final List<DateTime> previewMonths;
  final int startOffset;
  final Map<String, Map<String, dynamic>> localIncomes;
  final bool isSaving;

  const IngresosState({
    this.months = 1,
    this.previewMonths = const [],
    this.startOffset = 0,
    this.localIncomes = const {},
    this.isSaving = false,
  });

  IngresosState copyWith({
    int? months,
    List<DateTime>? previewMonths,
    int? startOffset,
    Map<String, Map<String, dynamic>>? localIncomes,
    bool? isSaving,
  }) {
    return IngresosState(
      months: months ?? this.months,
      previewMonths: previewMonths ?? this.previewMonths,
      startOffset: startOffset ?? this.startOffset,
      localIncomes: localIncomes ?? this.localIncomes,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
