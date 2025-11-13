class ImprevistosState {
  final bool showMaxError;
  final bool isAmountValid;
  final bool isSaving;
  final int selectedMonthOffset;

  const ImprevistosState({
    this.showMaxError = false,
    this.isAmountValid = false,
    this.isSaving = false,
    this.selectedMonthOffset = 0,
  });

  ImprevistosState copyWith({
    bool? showMaxError,
    bool? isAmountValid,
    bool? isSaving,
    int? selectedMonthOffset,
  }) {
    return ImprevistosState(
      showMaxError: showMaxError ?? this.showMaxError,
      isAmountValid: isAmountValid ?? this.isAmountValid,
      isSaving: isSaving ?? this.isSaving,
      selectedMonthOffset: selectedMonthOffset ?? this.selectedMonthOffset,
    );
  }
}
