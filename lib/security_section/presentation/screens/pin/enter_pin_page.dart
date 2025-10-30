// ignore: unused_element
import 'dart:async';
import 'package:app_wallet/library_section/main_library.dart';

class EnterPinPage extends StatefulWidget {
  final bool verifyOnly;
  final String? accountId;

  const EnterPinPage({Key? key, this.verifyOnly = false, this.accountId})
      : super(key: key);

  @override
  State<EnterPinPage> createState() => _EnterPinPageState();
}

class _EnterPinPageState extends State<EnterPinPage> {
  int _attempts = 0;
  String? _alias;
  final GlobalKey<PinEntryAreaState> _pinKey = GlobalKey<PinEntryAreaState>();
  Duration? _lockedRemaining;
  // Controller que encapsula el polling de lockedRemaining por accountId
  LockStatusController? _lockCtrl;
  StreamSubscription<User?>? _authSub;
  late final EnterPinViewModel _viewModel;
  bool _hasConnection = true;
  bool _showFailurePopup = false;
  int _remainingAttempts = 0;
  // (la bandera de Snack se delega al LockStatusController)
  StreamSubscription<ConnectivityResult>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _viewModel = EnterPinViewModel();
    _loadAlias();
    _loadAttempts();
    _updateLockState();
    _checkConnection();
    // Escuchar cambios de conectividad para que la UI se actualice mientras esta página está activa
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      setState(() {
        _hasConnection = result != ConnectivityResult.none;
      });
    });

    // Mantener sincronizado el controller si el usuario cambia de cuenta.
    // Si se pasó `accountId` explícitamente (por ejemplo desde logout), no necesitamos
    // suscribirnos a authStateChanges porque trabajamos con ese id fijo.
    if (widget.accountId == null) {
      _authSub =
          FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
      // inicializar controller con usuario actual si existe
      _onAuthChanged(FirebaseAuth.instance.currentUser);
    } else {
      // Crear y arrancar el LockStatusController para el accountId proporcionado
      () async {
        _lockCtrl = LockStatusController(accountId: widget.accountId!);
        await _lockCtrl!.start();
        _lockCtrl!.lockedRemaining.addListener(() {
          if (!mounted) return;
          setState(() {
            _lockedRemaining = _lockCtrl!.lockedRemaining.value;
          });
        });
        _lockCtrl!.isLocked.addListener(() {
          if (!mounted) return;
          if (_lockCtrl!.isLocked.value && !_lockCtrl!.shownLockSnack) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Demasiados intentos fallidos. Intenta nuevamente en ${PinService.lockDuration.inMinutes} minutos.')));
            _lockCtrl!.markShownLockSnack();
          }
        });
      }();
    }
  }

  Future<void> _onAuthChanged(User? user) async {
    // Desechar el controlador anterior si existe
    if (_lockCtrl != null) {
      _lockCtrl!.dispose();
      _lockCtrl = null;
    }

    if (user == null) {
      if (!mounted) return;
      setState(() {
        _lockedRemaining = null;
      });
      return;
    }

    // Crear e iniciar el controlador para el nuevo accountId
    _lockCtrl = LockStatusController(accountId: user.uid);
    await _lockCtrl!.start();

    // Conectar los notifiers para actualizar el estado local
    _lockCtrl!.lockedRemaining.addListener(() {
      if (!mounted) return;
      setState(() {
        _lockedRemaining = _lockCtrl!.lockedRemaining.value;
      });
    });

    _lockCtrl!.isLocked.addListener(() {
      if (!mounted) return;
      if (_lockCtrl!.isLocked.value && !_lockCtrl!.shownLockSnack) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Demasiados intentos fallidos. Intenta nuevamente en ${PinService.lockDuration.inMinutes} minutos.')));
        _lockCtrl!.markShownLockSnack();
      }
    });
  }

  Future<void> _checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() {
      _hasConnection = connectivityResult != ConnectivityResult.none;
    });
  }

  Future<void> _loadAttempts() async {
    final uid = widget.accountId ?? AuthService().getCurrentUser()?.uid;
    if (uid == null) return;
    await _viewModel.loadAttempts(uid);
    if (!mounted) return;
    setState(() {
      _attempts = _viewModel.attempts.value;
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _lockCtrl?.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _loadAlias() async {
    final uid = widget.accountId ?? AuthService().getCurrentUser()?.uid;
    if (uid == null) return;
    final pinService = PinService();
    final a = await pinService.getAlias(accountId: uid);
    if (!mounted) return;
    setState(() {
      _alias = a;
    });
  }

  Future<void> _updateLockState([String? accountId]) async {
    final uid =
        accountId ?? widget.accountId ?? AuthService().getCurrentUser()?.uid;
    if (uid == null) return;
    // Si hay controller, usarlo (polling ya centralizado). Si no, hacer una
    // consulta puntual a PinService como fallback.
    if (_lockCtrl != null) {
      await _lockCtrl!.refresh();
      if (!mounted) return;
      setState(() {
        _lockedRemaining = _lockCtrl!.lockedRemaining.value;
      });
      return;
    }

    final remaining = await PinService().lockedRemaining(accountId: uid);
    if (!mounted) return;
    setState(() {
      _lockedRemaining = remaining;
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _onCompleted(String pin) async {
    final accountId =
        widget.accountId ?? AuthService().getCurrentUser()?.uid ?? '';
    final ok = await _viewModel.verifyPin(accountId: accountId, pin: pin);
    if (ok) {
      if (widget.verifyOnly) {
        Navigator.of(context).pop(true);
        return;
      }
      await Flushbar(
        message: 'PIN correcto',
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WalletHomePage()),
      );
    } else {
      if (mounted) {
        setState(() {
          _attempts = _viewModel.attempts.value;
        });
      }
      // Si ok es true, ya manejamos el éxito arriba; si es false, continuar manejando el fallo
      if (ok) return;
      // Limpiar la entrada
      _pinKey.currentState?.clear();

      // Comprobar si la cuenta quedó bloqueada por este intento fallido.
      final lockedNow =
          await PinService().lockedRemaining(accountId: accountId);
      if (!mounted) return;
      if (lockedNow != null) {
        // Existe bloqueo: actualizar estado de bloqueo y no mostrar el popup de reintento
        await _updateLockState(accountId);
        if (!mounted) return;
        setState(() {
          _remainingAttempts = 0;
          _showFailurePopup = false;
        });
        // Mostrar la notificación de bloqueo.
        if (_lockCtrl != null) {
          if (!_lockCtrl!.shownLockSnack) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Demasiados intentos fallidos. Intenta nuevamente en ${PinService.lockDuration.inMinutes} minutos.')));
            _lockCtrl!.markShownLockSnack();
          }
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Demasiados intentos fallidos. Intenta nuevamente en ${PinService.lockDuration.inMinutes} minutos.')));
        }
        return;
      }

      // Determinar los intentos restantes y mostrar un popup en pantalla
      final remaining = PinService.maxAttempts - _attempts;
      if (!mounted) return;
      setState(() {
        _remainingAttempts = remaining >= 0 ? remaining : 0;
        _showFailurePopup = true;
      });

      await _updateLockState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 0),
                          if (_alias != null && _alias!.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Transform.translate(
                                offset: const Offset(0, -6),
                                child: AwText.bold('Hola ${_alias!}...',
                                    size: AwSize.s30,
                                    color: AwColors.appBarColor),
                              ),
                            ),
                            AwSpacing.s12,
                          ],
                          const AwText.normal('Ingresa tu PIN'),
                          AwSpacing.s12,
                          if (_lockedRemaining != null) ...[
                            const AwText.bold('Cuenta bloqueada',
                                color: AwColors.red),
                            AwSpacing.s,
                            AwText.normal(
                                'Intenta nuevamente en ${_formatDuration(_lockedRemaining!)}'),
                            AwSpacing.s20,
                          ] else ...[
                            PinEntryArea(
                                key: _pinKey,
                                digits: 4,
                                onCompleted: (_) {},
                                actions: Column(
                                  children: [
                                    // Botón de confirmar: el usuario debe pulsarlo para enviar el PIN
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: WalletButton.iconButtonText(
                                        buttonText: 'Confirmar',
                                        onPressed: () async {
                                          final pin = _pinKey
                                                  .currentState?.currentPin ??
                                              '';
                                          if (pin.length < 4) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Ingresa el PIN completo')));
                                            return;
                                          }
                                          await _onCompleted(pin);
                                        },
                                        backgroundColor: AwColors.appBarColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    PinActions(
                                      hasConnection: _hasConnection,
                                      onNotYou: () async {
                                        try {
                                          await FirebaseAuth.instance.signOut();
                                        } catch (_) {}
                                        await AuthService().clearLoginState();
                                        if (!mounted) return;
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const LoginScreen()),
                                        );
                                      },
                                      onForgotPin: () async {
                                        // Abrir la pantalla local de 'Olvidé mi PIN'
                                        final email = AuthService()
                                            .getCurrentUser()
                                            ?.email;
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ForgotPinPage(
                                              initialEmail: email,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                )),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // (Las acciones de PIN ahora se muestran justo debajo del teclado numérico)
              ],
            ),
            if (_showFailurePopup)
              FailureOverlay(
                visible: _showFailurePopup,
                remainingAttempts: _remainingAttempts,
                onRetry: () {
                  try {
                    _pinKey.currentState?.clear();
                  } catch (_) {}
                  setState(() {
                    _showFailurePopup = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
