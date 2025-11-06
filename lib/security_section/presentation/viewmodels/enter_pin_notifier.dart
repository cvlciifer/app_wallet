import 'dart:async';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'enter_pin_state.dart';

/// StateNotifier que maneja la lógica de ingresar PIN para una cuenta
class EnterPinNotifier extends StateNotifier<EnterPinState> {
  final Ref ref;
  final String accountId;
  final PinService _pinService;

  Timer? _lockTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySub;

  EnterPinNotifier(this.ref, this.accountId, {PinService? pinService})
      : _pinService = pinService ?? PinService(),
        super(const EnterPinState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final alias = await _pinService.getAlias(accountId: accountId);
      final attempts =
          await _pinService.getFailedAttempts(accountId: accountId);
      final locked = await _pinService.lockedRemaining(accountId: accountId);

      bool hasConn = true;
      try {
        final res = await Connectivity().checkConnectivity();
        hasConn = res != ConnectivityResult.none;
      } catch (_) {}
      // subscribe to connectivity changes
      _connectivitySub = Connectivity().onConnectivityChanged.listen((r) {
        state = state.copyWith(hasConnection: r != ConnectivityResult.none);
      });
      state = state.copyWith(
          alias: alias,
          attempts: attempts,
          isLoading: false,
          hasConnection: hasConn,
          lockedRemaining: locked);
      _maybeStartLockTimer(locked);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void _maybeStartLockTimer(Duration? remaining) {
    _lockTimer?.cancel();
    if (remaining == null) return;
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final r = await _pinService.lockedRemaining(accountId: accountId);
      if (r == null) {
        _lockTimer?.cancel();
      }
      state = state.copyWith(lockedRemaining: r);
    });
  }

  Future<bool> verifyPin({required String pin}) async {
    state = state.copyWith(isWorking: true);
    try {
      final ok = await _pinService.verifyPin(accountId: accountId, pin: pin);
      final attempts =
          ok ? 0 : await _pinService.getFailedAttempts(accountId: accountId);
      final locked = await _pinService.lockedRemaining(accountId: accountId);
      state = state.copyWith(
          attempts: attempts, isWorking: false, lockedRemaining: locked);
      if (locked != null) {
        _maybeStartLockTimer(locked);
      }
      return ok;
    } catch (_) {
      state = state.copyWith(isWorking: false);
      return false;
    }
  }

  Future<void> refreshAttempts() async {
    final attempts = await _pinService.getFailedAttempts(accountId: accountId);
    state = state.copyWith(attempts: attempts);
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }
}

final enterPinProvider = StateNotifierProvider.autoDispose
    .family<EnterPinNotifier, EnterPinState, String>(
  (ref, accountId) => EnterPinNotifier(ref, accountId),
);
