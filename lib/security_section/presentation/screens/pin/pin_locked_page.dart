import 'dart:async';
import 'package:app_wallet/library_section/main_library.dart';

class PinLockedPage extends StatefulWidget {
  final Duration remaining;
  final String? message;
  final bool allowBack;

  const PinLockedPage(
      {Key? key, required this.remaining, this.message, this.allowBack = false})
      : super(key: key);

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
    return Scaffold(
      appBar: widget.allowBack
          ? WalletAppBar(
              showBackArrow: false,
              title: ' ',
              barColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: AwColors.appBarColor),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Center(
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
                        final uid = AuthService().getCurrentUser()?.uid;
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => EnterPinPage(accountId: uid)));
                      }
                    : null,
                backgroundColor: AwColors.appBarColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
