import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/library_section/main_library.dart';

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
  String? _alias;
  String? _secondPin;
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
      _secondPin = pin;
    });
  }

  Future<void> _save() async {
    _secondPin = _pinKey.currentState?.currentPin ?? _secondPin;

    if (_secondPin == null || _secondPin != widget.firstPin) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Los PIN no coinciden')));
      return;
    }
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no identificado')));
      return;
    }
    final pinService = PinService();
    try {
      try {
        ProviderScope.containerOf(context, listen: false)
            .read(globalLoaderProvider.notifier)
            .show();
      } catch (_) {}

      await pinService.setPin(
          accountId: uid,
          pin: _secondPin!,
          digits: widget.digits,
          alias: widget.alias);

      try {
        ProviderScope.containerOf(context, listen: false)
            .read(globalLoaderProvider.notifier)
            .hide();
      } catch (_) {}
    } catch (e) {
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      try {
        ProviderScope.containerOf(context, listen: false)
            .read(globalLoaderProvider.notifier)
            .hide();
      } catch (_) {}
      return;
    }

    try {
      ProviderScope.containerOf(context, listen: false)
          .read(resetFlowProvider.notifier)
          .clear();
    } catch (_) {}
    try {
      final aliasOk = await AliasService().syncAliasForCurrentUser();
      log('ConfirmPinPage: syncAliasForCurrentUser result=$aliasOk',
          name: 'ConfirmPinPage');
    } catch (e, st) {
      log('ConfirmPinPage: syncAliasForCurrentUser error=$e',
          name: 'ConfirmPinPage', error: e, stackTrace: st);
    }
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN configurado correctamente')));

    final persisted = await pinService.hasPin(accountId: uid);
    if (!persisted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error guardando el PIN. Intenta de nuevo.')));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WalletHomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PinPageScaffold(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AwSpacing.s12,
                  GreetingHeader(alias: _alias ?? widget.alias),
                  AwSpacing.s12,
                  const AwText.bold('Confirma tu PIN',
                      size: AwSize.s16, color: AwColors.appBarColor),
                  AwSpacing.s12,
                  PinEntryArea(
                    key: _pinKey,
                    digits: widget.digits,
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
                              final len =
                                  _pinKey.currentState?.currentLength ?? 0;
                              final ready = len == widget.digits;
                              return ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                      // ignore: deprecated_member_use
                                      MaterialStateProperty.resolveWith(
                                          (states) => states.contains(
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
                                        _secondPin =
                                            _pinKey.currentState?.currentPin ??
                                                '';
                                        _save();
                                      }
                                    : null,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14.0),
                                  child: AwText.bold('Guardar PIN',
                                      color: Colors.white),
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
            ),
          ),
        ],
      ),
    );
  }
}
