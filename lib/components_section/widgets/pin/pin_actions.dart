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
            child: LayoutBuilder(builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final showInline = maxW.isFinite && maxW >= 300;

              if (showInline) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    UnderlinedButton(
                      text: 'Olvidé mi PIN',
                      icon: Icons.lock_reset,
                      color: AwColors.blue,
                      onTap: () async {
                        await onForgotPin();
                      },
                    ),
                    AwSpacing.s12,
                    UnderlinedButton(
                      text: '¿No eres tú?',
                      onTap: onNotYou,
                      color: AwColors.blue,
                    ),
                  ],
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  UnderlinedButton(
                    text: 'Olvidé mi PIN',
                    icon: Icons.lock_reset,
                    color: AwColors.blue,
                    onTap: () async {
                      await onForgotPin();
                    },
                  ),
                  AwSpacing.s,
                  UnderlinedButton(
                    text: '¿No eres tú?',
                    onTap: onNotYou,
                    color: AwColors.blue,
                  ),
                ],
              );
            }),
          ),
        // Se removieron opciones de depuración de la UI en producción.
      ],
    );
  }
}
