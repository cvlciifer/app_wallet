import 'package:app_wallet/library_section/main_library.dart';

class AliasInputPage extends StatefulWidget {
  final bool initialSetup;

  const AliasInputPage({Key? key, this.initialSetup = false}) : super(key: key);

  @override
  State<AliasInputPage> createState() => _AliasInputPageState();
}

class _AliasInputPageState extends State<AliasInputPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _canContinue = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _confirmController.addListener(_onTextChanged);
    // sin acción
  }

  void _onTextChanged() {
    final a = _controller.text.trim();
    final b = _confirmController.text.trim();
    final enabled = _aliasesMatch() && _isAliasValid(a) && _isAliasValid(b);
    if (enabled != _canContinue) {
      setState(() {
        _canContinue = enabled;
      });
    }
  }

  void _continue() async {
    final alias = _controller.text.trim();
    final confirm = _confirmController.text.trim();
    if (alias.isEmpty || confirm.isEmpty || !_aliasesMatch()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Los alias deben coincidir')));
      return;
    }
    final normalized = alias.isEmpty ? null : alias;

    if (widget.initialSetup) {
      final uidCheck = AuthService().getCurrentUser()?.uid;
      final pinServiceCheck = PinService();
      final hasPinCheck =
          uidCheck != null && await pinServiceCheck.hasPin(accountId: uidCheck);
      if (hasPinCheck) {
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SetPinPage(alias: normalized),
        ));
        return;
      }
    }

    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no identificado')));
      return;
    }
    final pinService = PinService();
    await pinService.setAlias(accountId: uid, alias: normalized ?? '');

    try {
      final ok = await AliasService().syncAliasForCurrentUser();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Alias guardado localmente, pero no se pudo sincronizar')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sincronizando alias: $e')));
      }
    }
    if (!mounted) return;

    Navigator.of(context).pop(normalized);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _confirmController.removeListener(_onTextChanged);
    _controller.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _aliasesMatch() {
    final a = _controller.text.trim();
    final b = _confirmController.text.trim();
    return a.isNotEmpty && b.isNotEmpty && a == b;
  }

  bool _isAliasValid(String s) {
    final v = s.trim();
    if (v.isEmpty) return false;
    if (v.length > 15) return false;
    final re = RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ\s]+$');
    return re.hasMatch(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AwSpacing.xxl,
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AwColors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const AwText.bold(
                      'ADMIN WALLET',
                      size: AwSize.s30,
                      color: AwColors.appBarColor,
                    ),
                  ),
                ),
              ),
              AwSpacing.l,
              const AwText.normal(
                'Necesitamos que ingreses un alias para identificar este dispositivo al iniciar sesión.',
                color: AwColors.boldBlack,
                size: AwSize.s16,
                textAlign: TextAlign.center,
              ),
              AwSpacing.xl,
              CustomTextField(
                controller: _controller,
                label: 'Alias',
                maxLength: 15,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                onChanged: (_) {},
                hideCounter: false,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ\s]")),
                ],
              ),
              AwSpacing.s12,
              CustomTextField(
                controller: _confirmController,
                label: 'Confirma tu alias',
                maxLength: 15,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                onChanged: (_) {},
                hideCounter: false,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ\s]")),
                ],
              ),
              if ((_controller.text.trim().isNotEmpty &&
                      !_isAliasValid(_controller.text)) ||
                  (_confirmController.text.trim().isNotEmpty &&
                      !_isAliasValid(_confirmController.text)))
                const AwText.normal(
                    'Solo se permiten letras y espacios (máx 15 caracteres)',
                    color: AwColors.red),
              if (_controller.text.trim().isNotEmpty &&
                  _confirmController.text.trim().isNotEmpty &&
                  !_aliasesMatch())
                const AwText.normal(
                    'Los alias no coinciden (Verifica las mayúsculas)',
                    color: AwColors.red),
              AwSpacing.s20,
              Center(
                child: WalletButton.primaryButton(
                  buttonText: 'Confirmar',
                  onPressed: _canContinue ? _continue : null,
                  backgroundColor:
                      _canContinue ? AwColors.appBarColor : AwColors.grey,
                  buttonTextColor: AwColors.white,
                ),
              ),
              AwSpacing.s12,
              WalletButton.textButton(
                buttonText: 'Configurar más tarde',
                onPressed: () {
                  if (widget.initialSetup) {
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SetPinPage()));
                  } else {
                    Navigator.of(context).pop(null);
                  }
                },
                alignment: MainAxisAlignment.center,
                colorText: AwColors.blueGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
