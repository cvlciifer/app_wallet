import 'package:app_wallet/library_section/main_library.dart';

/// Envoltorio ligero que muestra el `PinFailurePopup` del proyecto cuando
/// [visible] es verdadero.
class FailureOverlay extends StatelessWidget {
  final bool visible;
  final int remainingAttempts;
  final VoidCallback onRetry;

  const FailureOverlay({
    Key? key,
    required this.visible,
    required this.remainingAttempts,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return PinFailurePopup(
      remainingAttempts: remainingAttempts,
      onRetry: onRetry,
    );
  }
}
