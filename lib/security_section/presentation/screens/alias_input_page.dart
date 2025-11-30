import 'package:app_wallet/library_section/main_library.dart';
import 'package:provider/provider.dart' as prov;

class AliasInputPage extends StatefulWidget {
  final bool initialSetup;

  const AliasInputPage({Key? key, this.initialSetup = false}) : super(key: key);

  @override
  State<AliasInputPage> createState() => _AliasInputPageState();
}

class _AliasInputPageState extends State<AliasInputPage> {
  final TextEditingController _controller = TextEditingController();
  bool _canContinue = false;
  bool _showInvalidChars = false;
  bool _maxAlertShown = false;
  Timer? _invalidCharTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final a = _controller.text.trim();
    final enabled = _isAliasValid(a);
    setState(() {
      _canContinue = enabled;
    });
    final len = _controller.text.length;
    if (len >= 15 && !_maxAlertShown) {
      _maxAlertShown = true;
      if (mounted) {
        WalletPopup.showNotificationWarningOrange(
          context: context,
          message: 'Has alcanzado el máximo de 15 caracteres',
          visibleTime: 2,
          isDismissible: true,
        );
      }
    } else if (len < 15 && _maxAlertShown) {
      _maxAlertShown = false;
    }
  }

  String? _aliasError(String s) {
    final v = s.trim();
    if (v.isEmpty) return null;
    if (v.length > 15) return 'Máximo 15 caracteres';
    if (!RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ\s]+$').hasMatch(v)) {
      return 'Solo se permiten letras y espacios';
    }
    if (!RegExp(r'[A-ZÀ-Ö]').hasMatch(v)) {
      return 'Se requiere al menos una letra mayúscula';
    }
    return null;
  }

  void _continue() async {
    final alias = _controller.text.trim();
    if (alias.isEmpty || !_isAliasValid(alias)) {
      if (!mounted) return;
      WalletPopup.showNotificationWarningOrange(
        context: context,
        message:
            'Alias inválido. Debe contener solo letras y espacios, tener al menos una mayúscula y máximo 15 caracteres',
        visibleTime: 2,
        isDismissible: true,
      );
      return;
    }
    final normalized = alias;

    if (widget.initialSetup) {
      final uidCheck = AuthService().getCurrentUser()?.uid;
      final pinServiceCheck = PinService();
      final hasPinCheck =
          uidCheck != null && await pinServiceCheck.hasPin(accountId: uidCheck);
      if (hasPinCheck) {
      } else {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SetPinPage(alias: normalized),
        ));
        return;
      }
    }

    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) {
      if (!mounted) return;
      WalletPopup.showNotificationWarningOrange(
        context: context,
        message: 'Usuario no identificado',
        visibleTime: 2,
        isDismissible: true,
      );
      return;
    }

    final aliasService = AliasService();
    try {
      await aliasService.setAliasForCurrentUser(normalized);
    } catch (e) {
      if (mounted) {
        WalletPopup.showNotificationWarningOrange(
          context: context,
          message: 'Error guardando alias localmente: $e',
          visibleTime: 3,
          isDismissible: true,
        );
      }
      return;
    }

    if (mounted) {
      try {
        final connectivity = await Connectivity().checkConnectivity();
        final offline = connectivity == ConnectivityResult.none;
        // ignore: use_build_context_synchronously
        final overlayCtx = Navigator.of(context).overlay?.context;

        if (overlayCtx != null) {
          Future.microtask(() async {
            await Future.delayed(const Duration(milliseconds: 120));
            try {
              if (offline) {
                WalletPopup.showNotificationSuccess(
                  // ignore: use_build_context_synchronously
                  context: overlayCtx,
                  title: 'Alias actualizado',
                  message: const AwText.normal(
                    'Será sincronizado cuando exista internet',
                    color: AwColors.white,
                    size: AwSize.s14,
                  ),
                  visibleTime: 2,
                  isDismissible: true,
                );
              } else {
                WalletPopup.showNotificationSuccess(
                  // ignore: use_build_context_synchronously
                  context: overlayCtx,
                  title: 'Alias actualizado',
                  visibleTime: 2,
                  isDismissible: true,
                );
              }
            } catch (_) {}
          });
        }
      } catch (_) {}
    }

    Future.microtask(() async {
      try {
        await aliasService.syncAliasForCurrentUser();
      } catch (_) {}
    });

    if (!mounted) return;
    Navigator.of(context).pop(normalized);
  }

  @override
  void dispose() {
    _invalidCharTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  bool _isAliasValid(String s) {
    final v = s.trim();
    if (v.isEmpty) return false;
    if (v.length > 15) return false;
    final re = RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ\s]+$');
    if (!re.hasMatch(v)) return false;
    final hasUpper = RegExp(r'[A-ZÀ-Ö]').hasMatch(v);
    return hasUpper;
  }

  @override
  Widget build(BuildContext context) {
    final aliasError = _aliasError(_controller.text);

    final aliasFromProvider = prov.Provider.of<AliasProvider>(context).alias;
    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: WalletAppBar(
        title: const AwText.bold('Configuraciones', color: AwColors.white),
        automaticallyImplyLeading: !widget.initialSetup,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AliasForm(
                controller: _controller,
                displayAlias: aliasFromProvider,
                aliasError: aliasError,
                canContinue: _canContinue,
                showInvalidChars: _showInvalidChars,
                onBlockedChars: () {
                  if (!mounted) return;
                  setState(() {
                    _showInvalidChars = true;
                  });
                  _invalidCharTimer?.cancel();
                  _invalidCharTimer = Timer(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() {
                        _showInvalidChars = false;
                      });
                    }
                  });
                },
                onChanged: (_) {},
                onConfirm: _continue,
                onConfigureLater: () {
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SetPinPage()));
                },
                initialSetup: widget.initialSetup,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
