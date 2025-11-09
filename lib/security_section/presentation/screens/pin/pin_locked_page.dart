import 'dart:async';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/components_section/widgets/pin/pin_page_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

class PinLockedPage extends StatefulWidget {
  final Duration remaining;
  final String? message;
  final bool allowBack;
  final bool returnToEnterPin;
  final String? accountId;

  const PinLockedPage({
    Key? key,
    required this.remaining,
    this.message,
    this.allowBack = false,
    this.returnToEnterPin = false,
    this.accountId,
  }) : super(key: key);

  @override
  State<PinLockedPage> createState() => _PinLockedPageState();
}

class _PinLockedPageState extends State<PinLockedPage> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.remaining;
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final ctx = context;
        riverpod.ProviderScope.containerOf(ctx, listen: false)
            .read(globalLoaderProvider.notifier)
            .state = false;
      } catch (_) {}
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_remaining > const Duration(seconds: 1)) {
          _remaining = _remaining - const Duration(seconds: 1);
        } else {
          _remaining = Duration.zero;
          _timer?.cancel();
        }
      });
    });
  }

  String _format(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      final h = hours.toString().padLeft(2, '0');
      return '$h:$minutes:$seconds';
    }
    return '${d.inMinutes.toString().padLeft(2, '0')}:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.returnToEnterPin) {
          final preferredUid =
              widget.accountId ?? AuthService().getCurrentUser()?.uid;
          if (preferredUid != null) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => EnterPinPage(accountId: preferredUid)));
            return false;
          }
        }
        return true;
      },
      child: PinPageScaffold(
        transparentAppBar: widget.allowBack,
        allowBack: widget.allowBack,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AwText.bold('Demasiados intentos',
                    size: AwSize.s30,
                    color: AwColors.appBarColor,
                    textAlign: TextAlign.center),
                AwSpacing.s20,
                AwText.normal(
                  widget.message ??
                      'Intenta nuevamente cuando termine el tiempo.',
                  textAlign: TextAlign.center,
                ),
                AwSpacing.s20,
                AwText.bold(_format(_remaining),
                    size: AwSize.s30, textAlign: TextAlign.center),
                AwSpacing.s20,
                WalletButton.primaryButton(
                  buttonText: _remaining == Duration.zero
                      ? 'Continuar'
                      : 'Volver cuando esté desbloqueado',
                  onPressed: _remaining == Duration.zero
                      ? () {
                          final preferredUid = widget.accountId ??
                              AuthService().getCurrentUser()?.uid;
                          if (preferredUid != null) {
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        EnterPinPage(accountId: preferredUid)));
                          } else {
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()));
                          }
                        }
                      : null,
                  backgroundColor: AwColors.appBarColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
