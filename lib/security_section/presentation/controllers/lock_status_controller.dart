import 'package:app_wallet/library_section/main_library.dart';
import 'dart:async';

/// Controller responsable de consultar el estado de bloqueo del PIN
/// Uso:
/// final ctrl = LockStatusController(accountId: uid);
/// await ctrl.start();
/// ctrl.lockedRemaining.addListener(() => ...);
/// ctrl.dispose();
class LockStatusController {
  final String accountId;
  final PinService _pinService;

  /// Notifier con el tiempo restante de bloqueo, o `null` si no está bloqueado.
  final ValueNotifier<Duration?> lockedRemaining = ValueNotifier(null);

  /// Notifier booleano útil si quieres mostrar/ocultar UI relacionada.
  final ValueNotifier<bool> isLocked = ValueNotifier(false);

  Timer? _timer;
  bool _shownLockSnack = false;

  LockStatusController({required this.accountId, PinService? pinService})
      : _pinService = pinService ?? PinService();

  /// Inicia la consulta periódica (1s) y hace una consulta inicial.
  Future<void> start() async {
    if (kDebugMode) debugPrint('LockStatusController.start for $accountId');
    await refresh();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await refresh();
    });
  }

  /// Fuerza una actualización inmediata del estado de bloqueo.
  Future<void> refresh() async {
    try {
      final r = await _pinService.lockedRemaining(accountId: accountId);
      lockedRemaining.value = r;
      isLocked.value = r != null;
      if (r == null) {
        // Si el bloqueo expiró, permitir volver a mostrar la notificación
        _shownLockSnack = false;
      }
    } catch (_) {
      // Silenciar errores; la UI puede volver a intentar.
    }
  }

  /// Indica si ya se mostró la notificación de bloqueo durante este periodo.
  bool get shownLockSnack => _shownLockSnack;

  /// Marca que la notificación de bloqueo ya fue mostrada.
  void markShownLockSnack() {
    _shownLockSnack = true;
  }

  /// Resetea la bandera para permitir que la notificación se muestre otra vez.
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
