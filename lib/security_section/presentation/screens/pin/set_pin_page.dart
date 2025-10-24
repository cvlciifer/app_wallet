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
              NumericKeypad(
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
