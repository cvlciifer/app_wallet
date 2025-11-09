import 'package:app_wallet/library_section/main_library.dart';

class EnterPinViewModel {
  final PinService _pinService;

  /// Notifier con intentos actuales
  final ValueNotifier<int> attempts = ValueNotifier<int>(0);

  EnterPinViewModel({PinService? pinService})
      : _pinService = pinService ?? PinService();

  Future<void> loadAttempts(String accountId) async {
    final a = await _pinService.getFailedAttempts(accountId: accountId);
    attempts.value = a;
  }

  Future<bool> verifyPin(
      {required String accountId, required String pin}) async {
    final ok = await _pinService.verifyPin(accountId: accountId, pin: pin);
    if (!ok) {
      final a = await _pinService.getFailedAttempts(accountId: accountId);
      attempts.value = a;
    } else {
      attempts.value = 0;
    }
    return ok;
  }

  Future<void> resetAttemptsDebug(String accountId) async {
    await _pinService.resetFailedAttempts(accountId: accountId);
    attempts.value = 0;
  }
}
