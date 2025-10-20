import 'package:app_wallet/library_section/main_library.dart';

class SetPinPage extends StatefulWidget {
  final String? alias;

  const SetPinPage({Key? key, this.alias}) : super(key: key);

  @override
  State<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  String? _firstPin;
  int _digits = 4;

  void _onCompleted(String pin) {
    setState(() {
      _firstPin = pin;
    });
  }

  void _confirm() {
    if (_firstPin == null || _firstPin!.length != _digits) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ingresa un PIN válido')));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ConfirmPinPage(
            firstPin: _firstPin!, digits: _digits, alias: widget.alias)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const AwText.bold(
        'Configura tu PIN de seguridad',
        size: AwSize.s20,
        color: AwColors.white,
      )),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AwSpacing.s12,
            const AwText.bold('Ingresa tu PIN', color: AwColors.boldBlack),
            AwSpacing.s20,
            PinInput(digits: _digits, onCompleted: _onCompleted),
            AwSpacing.s20,
            Center(
              child: WalletButton.primaryButton(
                buttonText: 'Continuar',
                onPressed: _confirm,
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

class ConfirmPinPage extends StatefulWidget {
  final String firstPin;
  final int digits;
  final String? alias;

  const ConfirmPinPage(
      {Key? key, required this.firstPin, this.digits = 4, this.alias})
      : super(key: key);

  @override
  State<ConfirmPinPage> createState() => _ConfirmPinPageState();
}

class _ConfirmPinPageState extends State<ConfirmPinPage> {
  String? _secondPin;

  void _onCompleted(String pin) {
    setState(() {
      _secondPin = pin;
    });
  }

  Future<void> _save() async {
    if (_secondPin == null || _secondPin != widget.firstPin) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Los PIN no coinciden')));
      return;
    }
    // Guarda el PIN usando el PinService
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no identificado')));
      return;
    }
    final pinService = PinService();
    await pinService.setPin(
        accountId: uid,
        pin: _secondPin!,
        digits: widget.digits,
        alias: widget.alias);
    // intenta sincronizar el alias al backend (no bloquea la UX)
    try {
      await AliasService().syncAliasForCurrentUser();
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN configurado correctamente')));

    final persisted = await pinService.hasPin(accountId: uid);
    if (!persisted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error guardando el PIN. Intenta de nuevo.')));
      return;
    }

    // Despues de configurar el PIN, ir al home de la app y eliminar rutas previas
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WalletHomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const AwText.bold('Configura tu PIN de seguridad',
              size: AwSize.s20, color: AwColors.white)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AwSpacing.s12,
            const AwText.bold('Confirma tu PIN', color: AwColors.boldBlack),
            AwSpacing.s12,
            if (widget.alias != null && widget.alias!.isNotEmpty) ...[
              AwText.normal('Ya casi estamos ${widget.alias!}...'),
              AwSpacing.s12,
            ],
            AwSpacing.s12,
            PinInput(digits: widget.digits, onCompleted: _onCompleted),
            AwSpacing.s20,
            Center(
              child: WalletButton.primaryButton(
                buttonText: 'Guardar PIN',
                onPressed: _save,
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
