import 'package:app_wallet/library_section/main_library.dart';

class AliasInputPage extends StatefulWidget {
  final bool initialSetup;

  const AliasInputPage({Key? key, this.initialSetup = false}) : super(key: key);

  @override
  State<AliasInputPage> createState() => _AliasInputPageState();
}

class _AliasInputPageState extends State<AliasInputPage> {
  final TextEditingController _controller = TextEditingController();
  bool _canContinue = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final enabled = _controller.text.trim().isNotEmpty;
    if (enabled != _canContinue) {
      setState(() {
        _canContinue = enabled;
      });
    }
  }

  void _continue() async {
    final alias = _controller.text.trim();
    final normalized = alias.isEmpty ? null : alias;

    if (widget.initialSetup) {
      // Para nuevos usuarios: ir a SetPinPage y pasar el alias capturado.
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SetPinPage(alias: normalized),
      ));
      return;
    }

    // Solo modo alias: guardar alias y luego ir a EnterPinPage para que el usuario aún deba ingresar el PIN
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no identificado')));
      return;
    }
    final pinService = PinService();
    await pinService.setAlias(accountId: uid, alias: normalized ?? '');
    // intenta sincronizar el alias al backend (no bloquea la UX)
    try {
      await AliasService().syncAliasForCurrentUser();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EnterPinPage()));
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        title: const AwText.bold(
          'Alias Admin Wallet',
          size: AwSize.s20,
          color: AwColors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const AwText.bold(
              'Ingresa un alias para este dispositivo',
              color: AwColors.boldBlack,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Alias',
                hintText: 'Ej: Ricardo Rojas',
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: WalletButton.primaryButton(
                buttonText: 'Confirmar',
                onPressed: _canContinue ? _continue : () {},
                backgroundColor: AwColors.appBarColor,
                buttonTextColor: AwColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
