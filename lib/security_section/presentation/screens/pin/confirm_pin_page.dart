import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/core/providers/reset_flow_provider.dart';
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
  String? _secondPin;
  final GlobalKey<PinInputState> _pinKey = GlobalKey<PinInputState>();
  bool _isWorking = false;

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
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no identificado')));
      return;
    }
    final pinService = PinService();
    try {
      await pinService.setPin(
          accountId: uid,
          pin: _secondPin!,
          digits: widget.digits,
          alias: widget.alias);
    } catch (e) {
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    try {
      ProviderScope.containerOf(context, listen: false)
          .read(resetFlowProvider.notifier)
          .clear();
    } catch (_) {}
    try {
      setState(() {
        _isWorking = true;
      });
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
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AwSpacing.s12,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AwText.bold(
                        widget.alias != null && widget.alias!.isNotEmpty
                            ? 'Hola ${widget.alias!}...'
                            : 'Hola...',
                        size: AwSize.s16,
                        color: AwColors.boldBlack),
                  ),
                  AwSpacing.s12,
                  const AwText.bold('Confirma tu PIN',
                      size: AwSize.s20, color: AwColors.appBarColor),
                  AwSpacing.s12,
                  PinInput(
                      key: _pinKey,
                      digits: widget.digits,
                      onCompleted: _onCompleted),
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
          if (_isWorking) ...[
            ModalBarrier(dismissible: false, color: AwColors.black54),
            Center(child: WalletLoader(color: AwColors.appBarColor)),
          ],
        ],
      ),
    );
  }
}
