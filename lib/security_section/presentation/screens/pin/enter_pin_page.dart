import 'dart:async';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/core/providers/reset_flow_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_wallet/core/sync_service/sync_service.dart';
import 'package:app_wallet/core/data_base_local/local_crud.dart';

class EnterPinPage extends ConsumerStatefulWidget {
  final bool verifyOnly;
  final String? accountId;

  const EnterPinPage({Key? key, this.verifyOnly = false, this.accountId})
      : super(key: key);

  @override
  ConsumerState<EnterPinPage> createState() => _EnterPinPageState();
}

class _EnterPinPageState extends ConsumerState<EnterPinPage> {
  String? _alias;
  final GlobalKey<PinEntryAreaState> _pinKey = GlobalKey<PinEntryAreaState>();
  Duration? _lockedRemaining;
  bool _navigatedToLocked = false;
  int _attempts = 0;
  bool _showFailurePopup = false;
  int _remainingAttempts = 0;
  VoidCallback? _attemptsListener;
  Timer? _failurePopupTimer;
  bool _showSuccessPopup = false;
  Timer? _successPopupTimer;
  bool _isWorking = false;

  LockStatusController? _lockCtrl;
  StreamSubscription<User?>? _authSub;
  late final EnterPinViewModel _viewModel;
  bool _hasConnection = true;

  StreamSubscription<ConnectivityResult>? _connectivitySub;
  bool _isRedirecting = false;
  Timer? _redirectTimeoutTimer;
  bool _resetListenerAttached = false;

  @override
  void initState() {
    super.initState();
    _viewModel = EnterPinViewModel();
    _attemptsListener = () {
      if (!mounted) return;
      setState(() {
        _attempts = _viewModel.attempts.value;
        final rem = PinService.maxAttempts - _attempts;
        _remainingAttempts = rem >= 0 ? rem : 0;
        _showFailurePopup = _attempts > 0;
      });
    };
    _viewModel.attempts.addListener(_attemptsListener!);
    _loadAlias();
    _loadAttempts();
    _updateLockState();
    _checkConnection();

    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      setState(() {
        _hasConnection = result != ConnectivityResult.none;
      });
    });

    if (widget.accountId == null) {
      _authSub =
          FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);

      _onAuthChanged(FirebaseAuth.instance.currentUser);
    } else {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _watchResetFlags();
    });
  }

  Future<void> _watchResetFlags() async {
    try {
      final current = ref.read(resetFlowProvider);
      if (current.status == ResetFlowStatus.allowed) {
        if (!mounted) return;
        setState(() => _isRedirecting = true);
        await Future.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SetPinPage()),
        );
        return;
      }
      if (current.status == ResetFlowStatus.processing) {
        if (!mounted) return;
        setState(() => _isRedirecting = true);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _onAuthChanged(User? user) async {
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

    _lockCtrl = LockStatusController(accountId: user.uid);
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

  void _attachResetListenerIfNeeded() {
    if (_resetListenerAttached) return;
    _resetListenerAttached = true;
    ref.listen<ResetFlowState>(resetFlowProvider, (previous, next) {
      if (next.status == ResetFlowStatus.processing) {
        if (!mounted) return;
        setState(() => _isRedirecting = true);
        _redirectTimeoutTimer?.cancel();
        _redirectTimeoutTimer = Timer(const Duration(seconds: 12), () {
          if (!mounted) return;
          setState(() => _isRedirecting = false);
        });
      } else if (next.status == ResetFlowStatus.allowed) {
        if (!mounted) return;
        setState(() => _isRedirecting = true);
        Future.microtask(() async {
          await Future.delayed(const Duration(milliseconds: 250));
          _redirectTimeoutTimer?.cancel();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SetPinPage()),
          );
        });
      } else if (next.status == ResetFlowStatus.idle) {
        if (!mounted) return;
        setState(() => _isRedirecting = false);
        _redirectTimeoutTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _failurePopupTimer?.cancel();
    _successPopupTimer?.cancel();
    _redirectTimeoutTimer?.cancel();
    _connectivitySub?.cancel();
    _authSub?.cancel();
    _lockCtrl?.dispose();
    if (_attemptsListener != null) {
      try {
        _viewModel.attempts.removeListener(_attemptsListener!);
      } catch (_) {}
      _attemptsListener = null;
    }
    super.dispose();
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

      _failurePopupTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _showSuccessPopup = true;
        _isWorking = true;
      });

      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      final syncService = SyncService(
        localCrud: LocalCrud(),
        firestore: FirebaseFirestore.instance,
        userEmail: email,
      );

      final initFuture =
          syncService.initializeLocalDbFromFirebase().catchError((e) {
        if (kDebugMode) print('init error: $e');
      });

      final waitFuture = Future.delayed(const Duration(seconds: 2));

      await Future.wait([initFuture, waitFuture]);

      if (!mounted) return;
      setState(() {
        _showSuccessPopup = false;
        _isWorking = false;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WalletHomePage()),
      );
    } else {
      if (mounted) {
        setState(() {
          _attempts = _viewModel.attempts.value;
        });
      }
      if (ok) return;

      _pinKey.currentState?.clear();

      final lockedNow =
          await PinService().lockedRemaining(accountId: accountId);
      if (!mounted) return;
      if (lockedNow != null) {
        await _updateLockState(accountId);
        if (!mounted) return;
        setState(() {
          _remainingAttempts = 0;
          _showFailurePopup = false;
        });

        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => PinLockedPage(
                remaining: lockedNow,
                message:
                    'Demasiados intentos fallidos. Intenta nuevamente en ${PinService.lockDuration.inMinutes} minutos.')));
        return;
      }

      final remaining = PinService.maxAttempts - _attempts;
      if (!mounted) return;
      setState(() {
        _remainingAttempts = remaining >= 0 ? remaining : 0;
        _showFailurePopup = true;
        _failurePopupTimer?.cancel();
        _failurePopupTimer = Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() {
            _showFailurePopup = false;
          });
        });
      });

      await _updateLockState();
    }
  }

  @override
  Widget build(BuildContext context) {
    _attachResetListenerIfNeeded();
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
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AwText.bold(
                                _alias != null && _alias!.isNotEmpty
                                    ? 'Hola ${_alias!}...'
                                    : 'Hola...',
                                size: AwSize.s30,
                                color: AwColors.appBarColor),
                          ),
                          AwSpacing.s12,
                          const AwText.normal('Ingresa tu PIN',
                              size: AwSize.s18, color: AwColors.boldBlack),
                          AwSpacing.s12,
                          if (_lockedRemaining != null) ...[
                            Builder(builder: (ctx) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                if (_navigatedToLocked) return;
                                _navigatedToLocked = true;
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) => PinLockedPage(
                                          remaining: _lockedRemaining!,
                                          message:
                                              'Demasiados intentos fallidos. Intenta nuevamente en ${PinService.lockDuration.inMinutes} minutos.')),
                                );
                              });
                              return const SizedBox.shrink();
                            }),
                          ] else ...[
                            PinEntryArea(
                                key: _pinKey,
                                digits: 4,
                                onCompleted: (_) {},
                                actions: Column(
                                  children: [
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
              ],
            ),
            if (_showFailurePopup) ...[
              EnterPinFailed(remainingAttempts: _remainingAttempts),
            ],
            if (_showSuccessPopup) ...[
              const EnterPinSuccessful(),
            ],
            if (_isWorking) ...[
              ModalBarrier(
                  dismissible: false, color: Colors.black.withOpacity(0.45)),
              Center(child: WalletLoader(color: AwColors.appBarColor)),
            ],
            if (_isRedirecting) ...[
              ModalBarrier(
                  dismissible: false, color: Colors.black.withOpacity(0.45)),
              Center(child: const WalletLoader()),
            ],
          ],
        ),
      ),
    );
  }
}
