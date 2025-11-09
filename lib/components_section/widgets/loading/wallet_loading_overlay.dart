import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter/material.dart';

class WalletLoadingOverlay extends StatefulWidget {
  final bool visible;
  final double backdropOpacity;
  final double iconSize;

  const WalletLoadingOverlay({
    Key? key,
    required this.visible,
    this.backdropOpacity = 0.45,
    this.iconSize = 88.0,
  }) : super(key: key);

  @override
  State<WalletLoadingOverlay> createState() => _WalletLoadingOverlayState();
}

class _WalletLoadingOverlayState extends State<WalletLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Semantics(
      label: 'Cargando',
      container: true,
      child: AbsorbPointer(
        absorbing: true,
        child: Stack(
          children: [
            // Backdrop
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withOpacity(widget.backdropOpacity),
            ),
            Center(
              child: RotationTransition(
                turns: _ctrl,
                child: Container(
                  width: widget.iconSize,
                  height: widget.iconSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: widget.iconSize * 0.56,
                    color: AwColors.appBarColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
