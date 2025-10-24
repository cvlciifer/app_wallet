import 'package:app_wallet/library_section/main_library.dart';

class ReauthenticatePage extends StatefulWidget {
  const ReauthenticatePage({Key? key}) : super(key: key);

  @override
  State<ReauthenticatePage> createState() => _ReauthenticatePageState();
}

class _ReauthenticatePageState extends State<ReauthenticatePage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _reauthenticate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;
    setState(() => _loading = true);
    try {
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: _passwordController.text);
      await user.reauthenticateWithCredential(cred);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reautenticación fallida')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reautenticarse')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const AwText.normal(
                'Ingresa tu contraseña para confirmar tu identidad.'),
            AwSpacing.s12,
            SizedBox(
              height: 60,
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  label:
                      const AwText(text: 'Contraseña', color: AwColors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            AwSpacing.s20,
            WalletButton.primaryButton(
              buttonText: _loading ? 'Validando...' : 'Confirmar',
              onPressed: _loading ? null : _reauthenticate,
            ),
          ],
        ),
      ),
    );
  }
}
