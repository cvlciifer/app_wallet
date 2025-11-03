import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPinPage extends StatefulWidget {
  final String? initialEmail;
  const ForgotPinPage({Key? key, this.initialEmail}) : super(key: key);

  @override
  State<ForgotPinPage> createState() => _ForgotPinPageState();
}

const String _functionsUrl = String.fromEnvironment(
  'RESET_API_URL',
  defaultValue: 'https://https://app-wallet-apis.vercel.app/request-reset',
);

class _ForgotPinPageState extends State<ForgotPinPage> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendRecoveryEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ingresa tu correo')));
      return;
    }
    try {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'pin_reset_email', value: email);

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
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Se envió un enlace a tu correo. Abre el enlace desde el móvil.')));
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
              const AwText.bold('Recuperar PIN', size: AwSize.s20),
              AwSpacing.s12,
              const AwText.normal(''),
              AwSpacing.s20,
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (para recuperar por correo)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              AwSpacing.s12,
              WalletButton.iconButtonText(
                buttonText: 'Enviar enlace por email.',
                onPressed: _sendRecoveryEmail,
                backgroundColor: AwColors.appBarColor,
              ),
              AwSpacing.s12,
            ],
          ),
        ),
      ),
    );
  }
}
