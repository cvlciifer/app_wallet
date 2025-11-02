import 'package:app_wallet/library_section/main_library.dart';
import 'dart:async';

class LockStatusController {
  final String accountId;
  final PinService _pinService;

  final ValueNotifier<Duration?> lockedRemaining = ValueNotifier(null);

  final ValueNotifier<bool> isLocked = ValueNotifier(false);

  Timer? _timer;
  bool _shownLockSnack = false;

  LockStatusController({required this.accountId, PinService? pinService})
      : _pinService = pinService ?? PinService();

  Future<void> start() async {
    if (kDebugMode) debugPrint('LockStatusController.start for $accountId');
    await refresh();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await refresh();
    });
  }

  Future<void> refresh() async {
    try {
      final r = await _pinService.lockedRemaining(accountId: accountId);
      lockedRemaining.value = r;
      isLocked.value = r != null;
      if (r == null) {
        _shownLockSnack = false;
      }
    } catch (_) {}
  }

  bool get shownLockSnack => _shownLockSnack;

  void markShownLockSnack() {
    _shownLockSnack = true;
  }

  void resetShownLockSnack() {
    _shownLockSnack = false;
  }

  void dispose() {
    if (kDebugMode) debugPrint('LockStatusController.dispose for $accountId');
    _timer?.cancel();
    lockedRemaining.dispose();
    isLocked.dispose();
  }
}
