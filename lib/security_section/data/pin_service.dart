import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pin_crypto.dart';

// Servicio para gestionar el PIN de seguridad
class PinService {
  final FlutterSecureStorage _storage;

  PinService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // Keys
  static const _kSalt = 'pin_salt';
  static const _kHash = 'pin_hash';
  static const _kDigits = 'pin_digits';
  static const _kVersion = 'pin_version';
  static const _kAlias = 'pin_alias';
  static const _kFailedAttempts = 'pin_failed_attempts';
  static const _kLockedUntil = 'pin_locked_until';

  // Configuración global de seguridad: máximo intentos y duración de bloqueo
  static const int maxAttempts = 3;
  static const Duration lockDuration = Duration(minutes: 2);

  String _ns(String base, String? accountId) =>
      accountId == null ? base : '$base:$accountId';

// si la app fue desinstalada y reinstalada, tiene que configurar nuevamente el alias y el pin
  static const _kInstallMarker = 'aw_install_marker_v1';

  Future<void> clearOnReinstallIfNeeded({required String accountId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_kInstallMarker) ?? false;
      if (!seen) {
        await prefs.setBool(_kInstallMarker, true);
        final has = await hasPin(accountId: accountId);
        if (has) {
          await removePin(accountId: accountId);
        }
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<bool> hasPin({required String accountId}) async {
    final h = await _storage.read(key: _ns(_kHash, accountId));
    return h != null;
  }

// Establecer PIN con versión 2 (PBKDF2)
  Future<void> setPin(
      {required String accountId,
      required String pin,
      required int digits,
      String? alias}) async {
    final salt = PinCrypto.randomSalt(16);
    final version = '2';
    final hash = await PinCrypto.deriveV2(pin, salt);

    await _storage.write(key: _ns(_kSalt, accountId), value: salt);
    await _storage.write(key: _ns(_kHash, accountId), value: hash);
    await _storage.write(key: _ns(_kVersion, accountId), value: version);
    await _storage.write(
        key: _ns(_kDigits, accountId), value: digits.toString());
    if (alias != null && alias.isNotEmpty) {
      await _storage.write(key: _ns(_kAlias, accountId), value: alias);
    }
    await resetFailedAttempts(accountId: accountId);
  }

// Quitar PIN y datos asociados
  Future<void> removePin({required String accountId}) async {
    await _storage.delete(key: _ns(_kHash, accountId));
    await _storage.delete(key: _ns(_kSalt, accountId));
    await _storage.delete(key: _ns(_kVersion, accountId));
    await _storage.delete(key: _ns(_kDigits, accountId));
    await _storage.delete(key: _ns(_kAlias, accountId));
    await resetFailedAttempts(accountId: accountId);
  }

// Obtener número de dígitos del PIN (por defecto 4)
  Future<int> getDigits({required String accountId}) async {
    final v = await _storage.read(key: _ns(_kDigits, accountId));
    if (v == null) return 4;
    return int.tryParse(v) ?? 4;
  }

// Obtener alias del PIN
  Future<String?> getAlias({required String accountId}) async {
    return await _storage.read(key: _ns(_kAlias, accountId));
  }

  Future<void> setAlias(
      {required String accountId, required String alias}) async {
    await _storage.write(key: _ns(_kAlias, accountId), value: alias);
  }

  // Verificar con migración: soporta legacy (v1) y v2 (PBKDF2).
  Future<bool> verifyPin(
      {required String accountId, required String pin}) async {
    if (await isLocked(accountId: accountId)) return false;

    final salt = await _storage.read(key: _ns(_kSalt, accountId));
    final hash = await _storage.read(key: _ns(_kHash, accountId));
    final version = await _storage.read(key: _ns(_kVersion, accountId));

    if (salt == null || hash == null) return false;

    try {
      if (version == null || version == '1') {
        final candidate = await PinCrypto.deriveLegacy(pin, salt);
        final ok = PinCrypto.constantTimeEquals(candidate, hash);
        if (ok) {
          try {
            final newHash = await PinCrypto.deriveV2(pin, salt);
            await _storage.write(key: _ns(_kHash, accountId), value: newHash);
            await _storage.write(key: _ns(_kVersion, accountId), value: '2');
          } catch (_) {}
          await resetFailedAttempts(accountId: accountId);
          return true;
        } else {
          await recordFailedAttempt(accountId: accountId);
          return false;
        }
      } else if (version == '2') {
        final candidate = await PinCrypto.deriveV2(pin, salt);
        final ok = PinCrypto.constantTimeEquals(candidate, hash);
        if (ok) {
          await resetFailedAttempts(accountId: accountId);
          return true;
        } else {
          await recordFailedAttempt(accountId: accountId);
          return false;
        }
      } else {
        await recordFailedAttempt(accountId: accountId);
        return false;
      }
    } catch (e) {
      await recordFailedAttempt(accountId: accountId);
      return false;
    }
  }

  // Intentos fallidos y bloqueo
  Future<int> _getFailedAttempts({required String accountId}) async {
    final s = await _storage.read(key: _ns(_kFailedAttempts, accountId));
    return int.tryParse(s ?? '0') ?? 0;
  }

  // Accessor público para intentos fallidos (usado por UI para mostrar estado)
  Future<int> getFailedAttempts({required String accountId}) async {
    return await _getFailedAttempts(accountId: accountId);
  }

// Resetear intentos fallidos
  Future<void> resetFailedAttempts({required String accountId}) async {
    await _storage.write(key: _ns(_kFailedAttempts, accountId), value: '0');
    await _storage.delete(key: _ns(_kLockedUntil, accountId));
  }

// Registrar intento fallido y posible bloqueo
  Future<void> recordFailedAttempt({required String accountId}) async {
    final attempts = await _getFailedAttempts(accountId: accountId);
    final newAttempts = attempts + 1;
    await _storage.write(
        key: _ns(_kFailedAttempts, accountId), value: newAttempts.toString());

    if (newAttempts >= PinService.maxAttempts) {
      final lockedUntil =
          DateTime.now().toUtc().add(PinService.lockDuration).toIso8601String();
      await _storage.write(
          key: _ns(_kLockedUntil, accountId), value: lockedUntil);
    }
  }

  // Verificar si está bloqueado
  Future<bool> isLocked({required String accountId}) async {
    final s = await _storage.read(key: _ns(_kLockedUntil, accountId));
    if (s == null) return false;
    final until = DateTime.tryParse(s);
    if (until == null) return false;
    return DateTime.now().toUtc().isBefore(until);
  }

  // Tiempo restante de bloqueo, o null si no está bloqueado
  Future<Duration?> lockedRemaining({required String accountId}) async {
    final s = await _storage.read(key: _ns(_kLockedUntil, accountId));
    if (s == null) return null;
    final until = DateTime.tryParse(s);
    if (until == null) return null;
    final now = DateTime.now().toUtc();
    if (now.isBefore(until)) return until.difference(now);
    return null;
  }
}
