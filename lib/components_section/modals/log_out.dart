import 'package:app_wallet/library_section/main_library.dart';

class LogOutDialog extends StatelessWidget {
  const LogOutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.logout,
            color: AwColors.orange,
            size: AwSize.s24,
          ),
          AwSpacing.w10,
          AwText.bold(
            'Cerrar sesión',
            size: AwSize.s16,
          ),
        ],
      ),
      content: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        child: AwText(
          text: '¿Seguro que quieres salir de tu cuenta?',
          color: AwColors.black,
          size: AwSize.s16,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final loginProvider =
                      Provider.of<LoginProvider>(context, listen: false);

                  await loginProvider.signOut();

                  try {
                    await AuthService().clearAllLoginState();
                  } catch (_) {}

                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AwColors.red,
                  foregroundColor: AwColors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 25.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const AwText(
                  text: 'Sí, cerrar sesión',
                  color: AwColors.white,
                  size: AwSize.s14,
                ),
              ),
            ),
            AwSpacing.s10,
            WalletButton.textButton(
              buttonText: 'Cancelar',
              alignment: MainAxisAlignment.center,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  static void showLogOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const LogOutDialog();
      },
    );
  }
}
