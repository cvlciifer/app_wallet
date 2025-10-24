import 'package:flutter/material.dart';
import 'package:app_wallet/library_section/main_library.dart';

/// Reusable failure popup shown when a PIN attempt fails.
/// Displays an icon, message, remaining attempts and a retry button.
class PinFailurePopup extends StatefulWidget {
  final int remainingAttempts;
  final VoidCallback onRetry;

  const PinFailurePopup(
      {Key? key, required this.remainingAttempts, required this.onRetry})
      : super(key: key);

  @override
  State<PinFailurePopup> createState() => _PinFailurePopupState();
}

class _PinFailurePopupState extends State<PinFailurePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AwColors.black54,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ScaleTransition(
            scale: _scale,
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.vpn_key, size: 48, color: AwColors.red),
                    AwSpacing.s12,
                    AwText.bold('PIN incorrecto', color: AwColors.red),
                    AwSpacing.s12,
                    AwText.normal('Quedan ${widget.remainingAttempts} intentos',
                        textAlign: TextAlign.center),
                    AwSpacing.s20,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        WalletButton.primaryButton(
                          buttonText: 'Volver a intentar',
                          onPressed: widget.onRetry,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
