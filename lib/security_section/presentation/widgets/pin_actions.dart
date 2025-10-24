import 'package:app_wallet/library_section/main_library.dart';

// pinactions son los botones debajo del PIN (no eres tú, olvidé mi PIN)

class PinActions extends StatelessWidget {
  final bool hasConnection;
  final VoidCallback onNotYou;
  final Future<void> Function() onForgotPin;

  const PinActions({
    Key? key,
    required this.hasConnection,
    required this.onNotYou,
    required this.onForgotPin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (hasConnection)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: WalletButton.iconButtonText(
                    buttonText: '¿No eres tú?',
                    onPressed: onNotYou,
                    backgroundColor: AwColors.blueGrey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WalletButton.iconButtonText(
                    buttonText: 'Olvidé mi PIN',
                    icon: Icons.lock_reset,
                    onPressed: () async {
                      await onForgotPin();
                    },
                    backgroundColor: AwColors.blue,
                  ),
                ),
              ],
            ),
          ),
        // Se removieron opciones de depuración de la UI en producción.
      ],
    );
  }
}
