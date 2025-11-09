import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ResetFlowStatus { idle, processing, allowed }

class ResetFlowState {
  final ResetFlowStatus status;
  final String? email;

  const ResetFlowState._(this.status, {this.email});

  const ResetFlowState.idle() : this._(ResetFlowStatus.idle);
  const ResetFlowState.processing() : this._(ResetFlowStatus.processing);
  const ResetFlowState.allowed([String? email])
      : this._(ResetFlowStatus.allowed, email: email);
}

class ResetFlowNotifier extends StateNotifier<ResetFlowState> {
  ResetFlowNotifier() : super(const ResetFlowState.idle());

  void setProcessing() => state = const ResetFlowState.processing();

  void setAllowed([String? email]) => state = ResetFlowState.allowed(email);

  void clear() => state = const ResetFlowState.idle();
}

final resetFlowProvider =
    StateNotifierProvider<ResetFlowNotifier, ResetFlowState>((ref) {
  return ResetFlowNotifier();
});
