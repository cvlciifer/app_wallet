import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:http/http.dart' as http;

const String _functionsUrl = String.fromEnvironment(
  'RESET_API_URL',
  defaultValue: 'https://app-wallet-apis.vercel.app/api/request-reset',
);

class ForgotPinNotifier extends StateNotifier<ForgotPinState> {
  final Ref ref;
  final String? accountId;
  Timer? _countdownTimer;

  ForgotPinNotifier(this.ref, this.accountId) : super(const ForgotPinState()) {
    _init();
  }

  Future<void> _init() async {
    final auth = AuthService();
    final saved = auth.getCurrentUser()?.email ?? '';
    state = state.copyWith(email: saved);
    if (accountId != null) {
      await loadAliasAndAttempts(accountId!);
    }
  }

  Future<void> loadAliasAndAttempts(String accountId) async {
    try {
      final pinService = PinService();
      final a = await pinService.getAlias(accountId: accountId);
      final remainingCount =
          await pinService.pinChangeRemainingCount(accountId: accountId);
      final cooldown =
          await pinService.pinChangeCooldownRemaining(accountId: accountId);
      final blockedUntil =
          await pinService.pinChangeBlockedUntilNextDay(accountId: accountId);

      if (cooldown != null) {
        state = state.copyWith(
            remainingSeconds: cooldown.inSeconds,
            alias: a,
            remainingAttempts: remainingCount);
        startCountdown(cooldown);
        return;
      }
      if (blockedUntil != null) {
        state = state.copyWith(alias: a, remainingAttempts: remainingCount);
        startCountdown(blockedUntil);
        return;
      }

      state = state.copyWith(alias: a, remainingAttempts: remainingCount);
    } catch (_) {
      // ignore
    }
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void startCountdown(Duration duration) {
    _countdownTimer?.cancel();
    final now = DateTime.now();
    final end = now.add(duration);
    state =
        state.copyWith(lastSentAt: now, remainingSeconds: duration.inSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final rem = end.difference(DateTime.now()).inSeconds;
      if (rem <= 0) {
        state = state.copyWith(remainingSeconds: 0);
        _countdownTimer?.cancel();
      } else {
        state = state.copyWith(remainingSeconds: rem);
      }
    });
  }

  void markSent() {
    final now = DateTime.now();
    state = state.copyWith(lastSentAt: now, remainingSeconds: 60);
    startCountdown(const Duration(seconds: 60));
  }

  Future<String> sendRecoveryEmail(String email) async {
    if (email.isEmpty) return 'No se encontró un correo asociado a esta cuenta';
    if (state.isSending) return 'Envío en curso';
    state = state.copyWith(isSending: true);
    try {
      final parsed = Uri.tryParse(_functionsUrl);
      if (parsed == null || parsed.host.isEmpty) {
        return 'URL del API inválida: "$_functionsUrl".';
      }

      final resp = await http.post(parsed,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        if (body['debugLink'] != null) {
          final debugLink = body['debugLink'] as String;
          if (kDebugMode) {
            developer.log('Debug reset link (SMTP not configured): $debugLink');
            markSent();
            return 'Enlace (debug) creado: $debugLink';
          }
        }
        markSent();
        final masked = _maskEmail(email);
        return 'Se envió un enlace a: $masked. Ábrelo desde este dispositivo.';
      }

      return 'Error al solicitar enlace: ${resp.statusCode} — ${resp.body}';
    } catch (e, st) {
      if (kDebugMode) {
        developer.log('sendSignInLinkToEmail error: $e');
        developer.log(st.toString());
      }
      final msg = e.toString();
      return 'Error al solicitar enlace: $msg';
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  String _maskEmail(String email) {
    try {
      final parts = email.split('@');
      if (parts.length != 2) return email;
      final local = parts[0];
      final domain = parts[1];
      final show = local.length <= 2 ? local : local.substring(0, 2);
      final starsCount = local.length - show.length;
      final stars = starsCount > 0 ? List.filled(starsCount, '*').join() : '';
      return '$show$stars@$domain';
    } catch (_) {
      return email;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

final forgotPinProvider = StateNotifierProvider.autoDispose
    .family<ForgotPinNotifier, ForgotPinState, String?>((ref, accountId) {
  return ForgotPinNotifier(ref, accountId);
});
