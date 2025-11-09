import 'package:flutter/foundation.dart';

@immutable
class ForgotPinState {
  final String email;
  final bool isSending;
  final DateTime? lastSentAt;
  final int remainingSeconds;
  final String? alias;
  final int remainingAttempts;

  const ForgotPinState({
    this.email = '',
    this.isSending = false,
    this.lastSentAt,
    this.remainingSeconds = 0,
    this.alias,
    this.remainingAttempts = 3,
  });

  ForgotPinState copyWith({
    String? email,
    bool? isSending,
    DateTime? lastSentAt,
    int? remainingSeconds,
    String? alias,
    int? remainingAttempts,
  }) {
    return ForgotPinState(
      email: email ?? this.email,
      isSending: isSending ?? this.isSending,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      alias: alias ?? this.alias,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
    );
  }
}
