import 'dart:developer';
import 'package:flutter/foundation.dart';
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
  OverlayEntry? _overlayEntry;

  void _onCompleted(String pin) {
    setState(() {
      _secondPin = pin;
    });
  }

  Future<void> _save() async {
    _secondPin = _pinKey.currentState?.currentPin ?? _secondPin;

    if (_secondPin == null || _secondPin != widget.firstPin) {
      WalletPopup.showNotificationWarningOrange(
        context: context,
        message: 'Los PIN no coinciden',
        visibleTime: 2,
        isDismissible: true,
      );
      return;
    }
    final uid = AuthService().getCurrentUser()?.uid;

    if (uid == null) {
      WalletPopup.showNotificationWarningOrange(
        context: context,
        message: 'Usuario no identificado',
        visibleTime: 2,
        isDismissible: true,
      );
      return;
    }
    final pinService = PinService();
    try {
      _showOverlay();
      setState(() {});

      await pinService.setPin(
          accountId: uid,
          pin: _secondPin!,
          digits: widget.digits,
          alias: widget.alias);
    } catch (e) {
      final msg = e.toString();
      WalletPopup.showNotificationWarningOrange(
        context: context,
        message: msg,
        visibleTime: 3,
        isDismissible: true,
      );
      _hideOverlay();
      setState(() {});
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
    WalletPopup.showNotificationSuccess(
      context: context,
      title: 'PIN configurado correctamente',
      visibleTime: 2,
      isDismissible: true,
    );

    final persisted = await pinService.hasPin(accountId: uid);
    if (!persisted) {
      if (!mounted) return;
      WalletPopup.showNotificationWarningOrange(
        context: context,
        message: 'Error guardando el PIN. Intenta de nuevo.',
        visibleTime: 3,
        isDismissible: true,
      );
      setState(() {});
      return;
    }
    if (!mounted) return;

    setState(() {});
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WalletHomePage()),
      (route) => false,
    );
  }

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

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(builder: (context) {
      return Positioned.fill(
        child: Material(
          color: Colors.black45,
          child: const Center(child: WalletLoader(color: AwColors.appBarColor)),
        ),
      );
    });
    try {
      Overlay.of(context).insert(_overlayEntry!);
    } catch (_) {}
  }

  void _hideOverlay() {
    try {
      _overlayEntry?.remove();
    } catch (_) {}
    _overlayEntry = null;
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
                  AwText.bold('Confirma tu PIN',
                      size: AwSize.s16, color: AwColors.appBarColor),
                  AwSpacing.s,
                  const AwText.normal(
                    'Confirma el PIN que ingresaste anteriormente para activar el acceso local.',
                    color: AwColors.boldBlack,
                    size: AwSize.s14,
                    textAlign: TextAlign.center,
                  ),
                  AwSpacing.s20,
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
                                      MaterialStateProperty.resolveWith(
                                          (states) => states.contains(
                                                  MaterialState.disabled)
                                              ? AwColors.blueGrey
                                              : AwColors.appBarColor),
                                  foregroundColor:
                                      MaterialStateProperty.resolveWith(
                                          (_) => Colors.white),
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
