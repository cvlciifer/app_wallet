/// Estado inmutable para EnterPin
class EnterPinState {
  final String? alias;
  final int attempts;
  final bool isLoading;
  final bool isWorking;
  final Duration? lockedRemaining;
  final bool hasConnection;

  const EnterPinState({
    this.alias,
    this.attempts = 0,
    this.isLoading = false,
    this.isWorking = false,
    this.lockedRemaining,
    this.hasConnection = true,
  });

  EnterPinState copyWith({
    String? alias,
    int? attempts,
    bool? isLoading,
    bool? isWorking,
    Duration? lockedRemaining,
    bool? hasConnection,
  }) {
    return EnterPinState(
      alias: alias ?? this.alias,
      attempts: attempts ?? this.attempts,
      isLoading: isLoading ?? this.isLoading,
      isWorking: isWorking ?? this.isWorking,
      lockedRemaining: lockedRemaining ?? this.lockedRemaining,
      hasConnection: hasConnection ?? this.hasConnection,
    );
  }
}
