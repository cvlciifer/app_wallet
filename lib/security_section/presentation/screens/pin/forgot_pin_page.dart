import 'package:app_wallet/library_section/main_library.dart';
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

  @override
  void initState() {
    super.initState();

    final userEmail = AuthService().getCurrentUser()?.email ?? '';
    _emailController =
        TextEditingController(text: widget.initialEmail ?? userEmail);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Se envió un enlace a: $email. Ábrelo desde este dispositivo.')));
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
      // Ensure the sending flag is always cleared so the resend button works.
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Olvidé mi PIN')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AwSpacing.s6,
              Builder(builder: (context) {
                final email = _emailController.text.trim();
                final primary =
                    'Se enviará un enlace de recuperación al correo asociado a tu cuenta: $email';
                return Center(child: AwText.normal(primary));
              }),
              AwSpacing.s12,
              Builder(builder: (context) {
                final isDisabled = _isSending || _remainingSeconds > 0;
                final hasSentBefore = _lastSentAt != null;
                final buttonText = _remainingSeconds > 0
                    ? 'Reenviar ($_remainingSeconds s)'
                    : (hasSentBefore ? 'Reenviar enlace' : 'Enviar enlace');
                return WalletButton.iconButtonText(
                  buttonText: buttonText,
                  onPressed: isDisabled ? () {} : _sendRecoveryEmail,
                  backgroundColor:
                      isDisabled ? AwColors.blueGrey : AwColors.appBarColor,
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
