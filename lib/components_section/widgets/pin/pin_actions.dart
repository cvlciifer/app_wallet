import 'package:app_wallet/library_section/main_library.dart';

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
                  child: UnderlinedButton(
                    text: '¿No eres tú?',
                    onTap: onNotYou,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: UnderlinedButton(
                    text: 'Olvidé mi PIN',
                    icon: Icons.lock_reset,
                    onTap: () async {
                      await onForgotPin();
                    },
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
