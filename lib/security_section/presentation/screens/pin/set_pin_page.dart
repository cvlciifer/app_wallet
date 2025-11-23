import 'package:app_wallet/library_section/main_library.dart';

class SetPinPage extends StatefulWidget {
  final String? alias;

  const SetPinPage({Key? key, this.alias}) : super(key: key);

  @override
  State<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  String? _alias;
  String? _firstPin;
  final int _digits = 4;
  final GlobalKey<PinEntryAreaState> _pinKey = GlobalKey<PinEntryAreaState>();

  @override
  void initState() {
    super.initState();
    _alias = widget.alias;
    if (_alias == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final a = await AliasService().getAliasForCurrentUser();
          if (!mounted) return;
          setState(() => _alias = a);
        } catch (_) {}
      });
    }
  }

  void _onCompleted(String pin) {
    setState(() {
      _firstPin = pin;
    });
  }

  void _confirm() {
    if (_firstPin == null || _firstPin!.length != _digits) {
      WalletPopup.showNotificationWarningOrange(
        context: context,
        message: 'Ingresa un PIN válido',
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ConfirmPinPage(
            firstPin: _firstPin!, digits: _digits, alias: widget.alias)));
  }

  @override
  Widget build(BuildContext context) {
    return PinPageScaffold(
      child: LayoutBuilder(builder: (ctx, constraints) {
        final mq = MediaQuery.of(ctx);
        final textScale = mq.textScaleFactor;
        final availH = constraints.maxHeight;
        final needsScroll = textScale > 1.05 || availH < 700 || mq.viewInsets.bottom > 0 || mq.viewPadding.bottom > 0;

        final content = Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: mq.viewPadding.bottom + (needsScroll ? 24.0 : 16.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AwSpacing.s12,
              GreetingHeader(alias: _alias ?? widget.alias),
              AwSpacing.s12,
              const AwText.bold('Configura tu PIN de seguridad',
                  size: AwSize.s16, color: AwColors.appBarColor),
              AwSpacing.s,
              const AwText.normal(
                'Este PIN protegerá el acceso local de la app en este dispositivo.',
                color: AwColors.boldBlack,
                size: AwSize.s14,
                textAlign: TextAlign.center,
              ),
              AwSpacing.s20,
              PinEntryArea(
                key: _pinKey,
                digits: _digits,
                autoComplete: false,
                onCompleted: _onCompleted,
                onChanged: (len) {
                  if (!mounted) return;
                  setState(() {});
                },
                actions: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: Builder(builder: (context) {
                          final len = _pinKey.currentState?.currentLength ?? 0;
                          final ready = len == _digits;
                          return ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  // ignore: deprecated_member_use
                                  MaterialStateProperty.resolveWith((states) =>
                                      states.contains(
                                              // ignore: deprecated_member_use
                                              MaterialState.disabled)
                                          ? AwColors.blueGrey
                                          : AwColors.appBarColor),
                              foregroundColor:
                                  // ignore: deprecated_member_use
                                  MaterialStateProperty.resolveWith(
                                      (states) => Colors.white),
                            ),
                            onPressed: ready
                                ? () {
                                    final pin =
                                        _pinKey.currentState?.currentPin ?? '';
                                    _firstPin = pin;
                                    _confirm();
                                  }
                                : null,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14.0),
                              child:
                                  AwText.bold('Continuar', color: Colors.white),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (needsScroll) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: availH),
              child: Center(child: content),
            ),
          );
        }

        return Center(child: content);
      }),
    );
  }
}
