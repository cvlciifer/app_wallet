import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_wallet/core/services/pin_crypto.dart';

class PinService {
  final FlutterSecureStorage _storage;

  PinService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _kSalt = 'pin_salt';
  static const _kHash = 'pin_hash';
  static const _kDigits = 'pin_digits';
  static const _kVersion = 'pin_version';
  static const _kAlias = 'pin_alias';
  static const _kFailedAttempts = 'pin_failed_attempts';
  static const _kLockedUntil = 'pin_locked_until';
  static const _kPinChangeCount = 'pin_change_count';
  static const _kPinChangeDay = 'pin_change_day';
  static const _kPinLastChange = 'pin_last_change';

  static const int maxVerifyAttempts = 3;
  static const Duration verifyLockDuration = Duration(minutes: 2);
  static const int maxAttempts = maxVerifyAttempts;
  static const Duration lockDuration = verifyLockDuration;
  // cambiar de 30 segs a 20 minutos
  static const Duration pinChangeCooldownDuration = Duration(seconds: 30);
  static const int pinChangeMaxPerDay = 3;

  String _ns(String base, String? accountId) =>
      accountId == null ? base : '$base:$accountId';

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

  Future<void> setPin({
    required String accountId,
    required String pin,
    required int digits,
    String? alias,
  }) async {
    try {
      final prefs = _storage;
      final dayKey = _ns(_kPinChangeDay, accountId);
      final countKey = _ns(_kPinChangeCount, accountId);
      final lastKey = _ns(_kPinLastChange, accountId);

      final now = DateTime.now().toUtc();
      final today = now.toIso8601String().split('T').first;

      final lastChangeStr = await prefs.read(key: lastKey);
      if (lastChangeStr != null) {
        try {
          final lastChange = DateTime.parse(lastChangeStr);
          final diff = now.difference(lastChange);
          if (diff < const Duration(minutes: 20)) {
            final remaining = PinService.pinChangeCooldownDuration - diff;
            final mins = remaining.inMinutes;
            throw Exception(
                'Debes esperar ${mins} min antes de cambiar el PIN nuevamente.');
          }
        } catch (_) {}
      }

      String? savedDay = await prefs.read(key: dayKey);
      int count = int.tryParse((await prefs.read(key: countKey)) ?? '0') ?? 0;
      if (savedDay != today) {
        count = 0;
      }
      if (count >= PinService.pinChangeMaxPerDay) {
        throw Exception(
            'Has alcanzado el límite de 3 cambios de PIN por día. Intenta mañana.');
      }
    } catch (e) {
      rethrow;
    }
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

    try {
      final prefs = _storage;
      final dayKey = _ns(_kPinChangeDay, accountId);
      final countKey = _ns(_kPinChangeCount, accountId);
      final lastKey = _ns(_kPinLastChange, accountId);
      final now = DateTime.now().toUtc();
      final today = now.toIso8601String().split('T').first;

      String? savedDay = await prefs.read(key: dayKey);
      int count = int.tryParse((await prefs.read(key: countKey)) ?? '0') ?? 0;
      if (savedDay != today) {
        count = 0;
      }
      count += 1;
      await prefs.write(key: dayKey, value: today);
      await prefs.write(key: countKey, value: count.toString());
      await prefs.write(key: lastKey, value: now.toIso8601String());
    } catch (_) {}
  }

  Future<void> removePin({required String accountId}) async {
    await _storage.delete(key: _ns(_kHash, accountId));
    await _storage.delete(key: _ns(_kSalt, accountId));
    await _storage.delete(key: _ns(_kVersion, accountId));
    await _storage.delete(key: _ns(_kDigits, accountId));
    await _storage.delete(key: _ns(_kAlias, accountId));
    await resetFailedAttempts(accountId: accountId);
  }

  Future<int> getDigits({required String accountId}) async {
    final v = await _storage.read(key: _ns(_kDigits, accountId));
    if (v == null) return 4;
    return int.tryParse(v) ?? 4;
  }

  Future<String?> getAlias({required String accountId}) async {
    return await _storage.read(key: _ns(_kAlias, accountId));
  }

  Future<void> setAlias(
      {required String accountId, required String alias}) async {
    await _storage.write(key: _ns(_kAlias, accountId), value: alias);
  }

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

  Future<int> _getFailedAttempts({required String accountId}) async {
    final s = await _storage.read(key: _ns(_kFailedAttempts, accountId));
    return int.tryParse(s ?? '0') ?? 0;
  }

  Future<int> getFailedAttempts({required String accountId}) async {
    return await _getFailedAttempts(accountId: accountId);
  }

  Future<void> resetFailedAttempts({required String accountId}) async {
    await _storage.write(key: _ns(_kFailedAttempts, accountId), value: '0');
    await _storage.delete(key: _ns(_kLockedUntil, accountId));
  }

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
      await _storage.write(key: _ns(_kFailedAttempts, accountId), value: '0');
    }
  }

  Future<bool> isLocked({required String accountId}) async {
    final s = await _storage.read(key: _ns(_kLockedUntil, accountId));
    if (s == null) return false;
    final until = DateTime.tryParse(s);
    if (until == null) return false;
    return DateTime.now().toUtc().isBefore(until);
  }

  Future<Duration?> lockedRemaining({required String accountId}) async {
    final s = await _storage.read(key: _ns(_kLockedUntil, accountId));
    if (s == null) return null;
    final until = DateTime.tryParse(s);
    if (until == null) return null;
    final now = DateTime.now().toUtc();
    if (now.isBefore(until)) return until.difference(now);
    return null;
  }

  Future<Duration?> pinChangeCooldownRemaining(
      {required String accountId}) async {
    final lastKey = _ns(_kPinLastChange, accountId);
    final s = await _storage.read(key: lastKey);
    if (s == null) return null;
    final last = DateTime.tryParse(s);
    if (last == null) return null;
    final now = DateTime.now().toUtc();
    final diff = now.difference(last);
    final cooldown = PinService.pinChangeCooldownDuration;
    if (diff < cooldown) return cooldown - diff;
    return null;
  }

  Future<int> pinChangeRemainingCount({required String accountId}) async {
    try {
      final prefs = _storage;
      final dayKey = _ns(_kPinChangeDay, accountId);
      final countKey = _ns(_kPinChangeCount, accountId);

      final now = DateTime.now().toUtc();
      final today = now.toIso8601String().split('T').first;

      final savedDay = await prefs.read(key: dayKey);
      int count = int.tryParse((await prefs.read(key: countKey)) ?? '0') ?? 0;
      if (savedDay != today) {
        count = 0;
      }
      final remaining = pinChangeMaxPerDay - count;
      return remaining < 0 ? 0 : remaining;
    } catch (_) {
      return maxAttempts;
    }
  }

  Future<Duration?> pinChangeBlockedUntilNextDay(
      {required String accountId}) async {
    try {
      final prefs = _storage;
      final dayKey = _ns(_kPinChangeDay, accountId);
      final countKey = _ns(_kPinChangeCount, accountId);

      final now = DateTime.now().toUtc();
      final today = now.toIso8601String().split('T').first;

      final savedDay = await prefs.read(key: dayKey);
      int count = int.tryParse((await prefs.read(key: countKey)) ?? '0') ?? 0;
      if (savedDay == null) return null;
      if (savedDay != today) {
        return null;
      }
      if (count < pinChangeMaxPerDay) return null;

      final lastKey = _ns(_kPinLastChange, accountId);
      final lastStr = await prefs.read(key: lastKey);
      if (lastStr != null) {
        final last = DateTime.tryParse(lastStr);
        if (last != null) {
          final blockedUntil = last.add(const Duration(days: 1));
          if (now.isBefore(blockedUntil)) return blockedUntil.difference(now);
          return null;
        }
      }

      final parts = savedDay.split('-');
      if (parts.length != 3) return null;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y == null || m == null || d == null) return null;
      final nextDay = DateTime.utc(y, m, d).add(const Duration(days: 1));
      if (now.isBefore(nextDay)) return nextDay.difference(now);
      return null;
    } catch (_) {
      return null;
    }
  }
}
