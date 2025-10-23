import 'package:app_wallet/library_section/main_library.dart';

class SetPinPage extends StatefulWidget {
  final String? alias;

  const SetPinPage({Key? key, this.alias}) : super(key: key);

  @override
  State<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  String? _firstPin;
  final int _digits = 4;
  // Keep a persistent GlobalKey so PinInput state is preserved across rebuilds
  final GlobalKey<PinInputState> _pinKey = GlobalKey<PinInputState>();

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AwSpacing.s12,
              const AwText.bold('Configura tu PIN de seguridad',
                  size: AwSize.s20, color: AwColors.appBarColor),
              AwSpacing.s,
              const AwText.normal(
                'Este PIN protegerá el acceso local de la app en este dispositivo.',
                color: AwColors.boldBlack,
                size: AwSize.s14,
                textAlign: TextAlign.center,
              ),
              AwSpacing.s20,
              PinInput(
                  key: _pinKey, digits: _digits, onCompleted: _onCompleted),
              AwSpacing.s20,
              _NumericKeypad(
                onDigit: (d) {
                  _pinKey.currentState?.appendDigit(d);
                  setState(() {});
                },
                onBackspace: () {
                  _pinKey.currentState?.deleteDigit();
                  setState(() {});
                },
              ),
              AwSpacing.s20,
              Center(
                child: Builder(builder: (context) {
                  final len = _pinKey.currentState?.currentLength ?? 0;
                  final ready = len == _digits;
                  return WalletButton.primaryButton(
                    buttonText: 'Continuar',
                    onPressed: ready ? _confirm : null,
                    backgroundColor:
                        ready ? AwColors.appBarColor : AwColors.blueGrey,
                    buttonTextColor:
                        ready ? AwColors.white : AwColors.boldBlack,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// pantalla de teclado numérico personalizada
class _NumericKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const _NumericKeypad(
      {Key? key, required this.onDigit, required this.onBackspace})
      : super(key: key);

  Widget _buildKey(String label, {VoidCallback? onTap}) {
    // si el label está vacío y no hay acción, renderiza un espaciador para mantener la simetría
    if (label.isEmpty && onTap == null) {
      return const Expanded(child: SizedBox());
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: SizedBox(
            width: 80,
            height: 80,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                shape: const CircleBorder(),
                // ignore: deprecated_member_use
                side: BorderSide(
                    color: AwColors.indigoInk.withOpacity(0.3), width: 2),
                padding: EdgeInsets.zero,
                // ignore: deprecated_member_use
                backgroundColor: AwColors.indigoInk.withOpacity(0.3),
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AwColors.boldBlack)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          for (var i in ['1', '2', '3']) _buildKey(i, onTap: () => onDigit(i))
        ]),
        Row(children: [
          for (var i in ['4', '5', '6']) _buildKey(i, onTap: () => onDigit(i))
        ]),
        Row(children: [
          for (var i in ['7', '8', '9']) _buildKey(i, onTap: () => onDigit(i))
        ]),
        Row(children: [
          _buildKey('', onTap: null),
          _buildKey('0', onTap: () => onDigit('0')),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: OutlinedButton(
                    onPressed: onBackspace,
                    style: OutlinedButton.styleFrom(
                      shape: const CircleBorder(),
                      side: BorderSide(
                          color: AwColors.indigoInk.withOpacity(0.3), width: 2),
                      padding: EdgeInsets.zero,
                      backgroundColor: AwColors.indigoInk.withOpacity(0.3),
                    ),
                    child:
                        const Icon(Icons.backspace, color: AwColors.boldBlack),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ],
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
  final GlobalKey<PinInputState> _pinKey = GlobalKey<PinInputState>();

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
    // // Después de configurar el PIN: mostrar animación de la billetera girando
    // if (!mounted) return;
    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (_) => const Dialog(
    //     backgroundColor: Colors.transparent,
    //     elevation: 0,
    //     child: SizedBox(
    //       height: 220,
    //       child: Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: [
    //           WalletLoader(),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
    // //mantener el diálogo visible por un corto tiempo
    // await Future.delayed(const Duration(milliseconds: 900));
    // if (mounted) Navigator.of(context, rootNavigator: true).pop();
    // if (!mounted) return;
    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(builder: (_) => const WalletHomePage()),
    //   (route) => false,
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar, mirror SetPinPage layout + keypad
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AwSpacing.s12,
              const AwText.bold('Confirma tu PIN',
                  size: AwSize.s20, color: AwColors.appBarColor),
              AwSpacing.s12,
              if (widget.alias != null && widget.alias!.isNotEmpty) ...[
                AwText.normal('Ya casi estamos ${widget.alias!}...'),
                AwSpacing.s12,
              ],
              AwSpacing.s12,
              PinInput(
                  key: _pinKey,
                  digits: widget.digits,
                  onCompleted: _onCompleted),
              AwSpacing.s20,
              _NumericKeypad(
                onDigit: (d) {
                  _pinKey.currentState?.appendDigit(d);
                  setState(() {});
                },
                onBackspace: () {
                  _pinKey.currentState?.deleteDigit();
                  setState(() {});
                },
              ),
              AwSpacing.s20,
              Center(
                child: Builder(builder: (context) {
                  final len = _pinKey.currentState?.currentLength ?? 0;
                  final ready = len == widget.digits;
                  return WalletButton.primaryButton(
                    buttonText: 'Guardar PIN',
                    onPressed: ready ? _save : null,
                    backgroundColor:
                        ready ? AwColors.appBarColor : AwColors.greyLight,
                    buttonTextColor:
                        ready ? AwColors.white : AwColors.boldBlack,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
