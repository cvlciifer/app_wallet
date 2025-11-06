import 'package:app_wallet/library_section/main_library.dart';
import 'pin_locked_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ForgotPinPage extends StatefulWidget {
  final String? initialEmail;
  const ForgotPinPage({Key? key, this.initialEmail}) : super(key: key);

  @override
  State<ForgotPinPage> createState() => _ForgotPinPageState();
}

const String _functionsUrl = String.fromEnvironment(
  'RESET_API_URL',
  defaultValue: 'https://app-wallet-apis.vercel.app/api/request-reset',
);

class _ForgotPinPageState extends State<ForgotPinPage> {
  late final TextEditingController _emailController;
  bool _isSending = false;
  DateTime? _lastSentAt;
  final Duration _resendCooldown = const Duration(seconds: 60);
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  String? _alias;
  int _remainingAttempts = PinService.maxAttempts;
  Timer? _primaryMessageTimer;

  @override
  void initState() {
    super.initState();

    final userEmail = AuthService().getCurrentUser()?.email ?? '';
    _emailController =
        TextEditingController(text: widget.initialEmail ?? userEmail);
    _loadAliasAndAttempts();
  }

  Future<void> _loadAliasAndAttempts() async {
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) return;
    try {
      final pinService = PinService();
      final a = await pinService.getAlias(accountId: uid);
      final remainingCount =
          await pinService.pinChangeRemainingCount(accountId: uid);
      final cooldown =
          await pinService.pinChangeCooldownRemaining(accountId: uid);
      final blockedUntil =
          await pinService.pinChangeBlockedUntilNextDay(accountId: uid);
      if (cooldown != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => PinLockedPage(
                remaining: cooldown,
                message:
                    'Debes esperar ${cooldown.inMinutes} min antes de cambiar el PIN nuevamente.',
                allowBack: true)));
        return;
      }
      if (blockedUntil != null) {
        if (!mounted) return;
        final mins = blockedUntil.inMinutes;
        final msg = blockedUntil >= const Duration(hours: 1)
            ? 'Has alcanzado el límite de 3 cambios de PIN por día. Intenta mañana.'
            : 'Has alcanzado el límite de cambios. Debes esperar ${mins} min antes de cambiar el PIN nuevamente.';
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => PinLockedPage(
                remaining: blockedUntil, message: msg, allowBack: true)));
        return;
      }
      if (!mounted) return;
      setState(() {
        _alias = (a != null && a.isNotEmpty)
            ? a
            : (AuthService().getCurrentUser()?.email ?? 'Usuario');
        _remainingAttempts = remainingCount;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _primaryMessageTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _markSent() {
    _lastSentAt = DateTime.now();
    _startCountdown();
    setState(() {});
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
      if (_remainingSeconds <= 0) {
        _countdownTimer?.cancel();
      }
    });
  }

  void _updateRemaining() {
    if (_lastSentAt == null) {
      setState(() => _remainingSeconds = 0);
      return;
    }
    final elapsed = DateTime.now().difference(_lastSentAt!);
    final rem = _resendCooldown - elapsed;
    setState(() => _remainingSeconds = rem.isNegative ? 0 : rem.inSeconds);
  }

  Future<void> _sendRecoveryEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se encontró un correo asociado a esta cuenta')));
      return;
    }
    if (_isSending) return;
    setState(() {
      _isSending = true;
    });
    try {
      final functionsUrl = _functionsUrl;

      final parsed = Uri.tryParse(functionsUrl);
      if (parsed == null || parsed.host.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'URL del API inválida: "$functionsUrl". Configura RESET_API_URL o usa --dart-define al ejecutar.')));
        return;
      }

      final resp = await http.post(parsed,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;

        if (body['debugLink'] != null) {
          final debugLink = body['debugLink'] as String;

          if (kDebugMode) {
            print('Debug reset link (SMTP not configured): $debugLink');
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Enlace (debug) creado: $debugLink')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Se envió un enlace a tu correo.')));
          }
          _markSent();
          return;
        } else {
          _markSent();
          final masked = _maskEmail(email);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Se envió un enlace a: $masked. Ábrelo desde este dispositivo.')));
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error al solicitar enlace: ${resp.statusCode} — ${resp.body}')));
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('sendSignInLinkToEmail error: $e');
        // ignore: avoid_print
        print(st);
      }
      final msg =
          e is FirebaseAuthException ? e.message ?? e.toString() : e.toString();
      final code = e is FirebaseAuthException ? e.code : null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(code != null
              ? 'Error al solicitar enlace: $code — $msg'
              : 'Error al solicitar enlace: $msg')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_alias != null && _alias!.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: AwText.bold(
                    'Hola ${_alias!}, ¿no recuerdas tu PIN?',
                    size: AwSize.s30,
                    color: AwColors.appBarColor,
                  ),
                ),
                AwSpacing.s12,
              ],
              if (!(_alias != null && _alias!.isNotEmpty)) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AwText.bold('Hola, ¿no recuerdas tu PIN?',
                      size: AwSize.s30, color: AwColors.appBarColor),
                ),
                AwSpacing.s12,
              ],
              const Align(
                  alignment: Alignment.centerLeft,
                  child: AwText.normal(
                      'No te preocupes, te ayudaremos a crear uno nuevo.',
                      color: AwColors.boldBlack,
                      size: AwSize.s14)),
              AwSpacing.s6,
              const Align(
                  alignment: Alignment.centerLeft,
                  child: AwText.normal(
                      'Para continuar, debes abrir ese enlace desde este mismo dispositivo.',
                      color: AwColors.boldBlack,
                      size: AwSize.s14)),
              SizedBox(
                height: 80,
                child: Container(color: Colors.white),
              ),
              Builder(builder: (context) {
                final hasSentBefore = _lastSentAt != null;
                final buttonText = _remainingSeconds > 0
                    ? 'Reenviar ($_remainingSeconds s)'
                    : (hasSentBefore ? 'Reenviar enlace' : 'Enviar enlace');

                final isResendLabel =
                    buttonText.toLowerCase().startsWith('reenviar');
                final isDisabled =
                    _isSending || _remainingSeconds > 0 || isResendLabel;

                return Column(
                  children: [
                    WalletButton.iconButtonText(
                      buttonText: buttonText,
                      onPressed: () {
                        if (isDisabled) return;
                        _sendRecoveryEmail();
                      },
                      backgroundColor: isResendLabel
                          ? AwColors.blueGrey
                          : AwColors.appBarColor,
                    ),
                    AwSpacing.s6,
                    // Remaining attempts text below the button (always visible)
                    AwText.normal(
                      'Hoy tienes $_remainingAttempts intento(s) para cambiar tu PIN.',
                      size: AwSize.s14,
                      color: AwColors.grey,
                    ),
                    AwSpacing.s12,
                  ],
                );
              }),
              AwSpacing.s12,
            ],
          ),
        ),
      ),
    );
  }
}
