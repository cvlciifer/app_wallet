import 'dart:async';
import 'package:app_wallet/library_section/main_library.dart';

class EnterPinPage extends StatefulWidget {
  const EnterPinPage({Key? key}) : super(key: key);

  @override
  State<EnterPinPage> createState() => _EnterPinPageState();
}

class _EnterPinPageState extends State<EnterPinPage> {
  int _attempts = 0;
  String? _alias;
  final GlobalKey<PinInputState> _pinKey = GlobalKey<PinInputState>();
  Duration? _lockedRemaining;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _loadAlias();
    _loadAttempts();
    // initial lock state
    _updateLockState();
  }

  Future<void> _loadAttempts() async {
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) return;
    final a = await PinService().getFailedAttempts(accountId: uid);
    if (!mounted) return;
    setState(() {
      _attempts = a;
    });
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAlias() async {
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) return;
    final pinService = PinService();
    final a = await pinService.getAlias(accountId: uid);
    if (!mounted) return;
    setState(() {
      _alias = a;
    });
  }

  Future<void> _updateLockState() async {
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) return;
    final remaining = await PinService().lockedRemaining(accountId: uid);
    if (!mounted) return;
    setState(() {
      _lockedRemaining = remaining;
    });
    _lockTimer?.cancel();
    if (remaining != null) {
      _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final r = await PinService().lockedRemaining(accountId: uid);
        if (!mounted) return;
        setState(() {
          _lockedRemaining = r;
        });
        if (r == null) {
          _lockTimer?.cancel();
        }
      });
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onCompleted(String pin) async {
    final uid = AuthService().getCurrentUser()?.uid;
    final pinService = PinService();
    final ok = await pinService.verifyPin(accountId: uid ?? '', pin: pin);
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WalletHomePage()),
      );
    } else {
      final uid2 = AuthService().getCurrentUser()?.uid;
      if (uid2 != null) {
        final a = await PinService().getFailedAttempts(accountId: uid2);
        if (mounted) {
          setState(() {
            _attempts = a;
          });
        }
      }
      // Clear the PIN input so the user can type again
      try {
        _pinKey.currentState?.clear();
      } catch (_) {}
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PIN incorrecto')));
      await _updateLockState();
      if (_attempts >= PinService.maxAttempts) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Demasiados intentos fallidos. Intenta nuevamente en ${PinService.lockDuration.inMinutes} minutos.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ingresa tu PIN',
          style: TextStyle(fontSize: AwSize.s20, color: AwColors.white),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_alias != null && _alias!.isNotEmpty) ...[
                AwText.bold('Que alegria verte de nuevo ${_alias!}...',
                    color: AwColors.boldBlack),
                AwSpacing.s,
                const AwText.large('Ingresa tu PIN'),
                AwSpacing.s20,
              ] else ...[
                const AwText.large('Ingresa tu PIN'),
                AwSpacing.s20,
              ],

              // If locked, show an informational panel instead of the PinInput
              if (_lockedRemaining != null) ...[
                AwText.bold('Cuenta bloqueada', color: AwColors.red),
                AwSpacing.s,
                AwText.normal(
                    'Intenta nuevamente en ${_formatDuration(_lockedRemaining!)}'),
                AwSpacing.s20,
              ] else ...[
                PinInput(key: _pinKey, digits: 4, onCompleted: _onCompleted),
              ],

              AwSpacing.s12,
              AwText.normal('Intentos: $_attempts / ${PinService.maxAttempts}'),
              AwSpacing.s12,
              Center(
                child: WalletButton.iconButtonText(
                  buttonText: '¿No eres tú?',
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                    } catch (_) {}
                    await AuthService().clearLoginState();
                    if (!mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  backgroundColor: AwColors.blueGrey,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
