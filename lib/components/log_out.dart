import 'package:app_wallet/library/main_library.dart';
import 'package:provider/provider.dart';

class LogOutDialog extends StatelessWidget {
  const LogOutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const AwText.bold(
        'Vas a cerrar sesión',
      ),
      content: const Row(
        children: [
          Icon(
            Icons.warning,
            color: AwColors.orange,
            size: AwSize.s24,
          ),
          AwSpacing.s10,
          Expanded(
            child: AwText(
              text: '¿Estás seguro?',
              color: AwColors.black,
              size: AwSize.s16,
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0), // Bordes redondeados
      ),
      actions: [
        WalletButton.textButton(
          buttonText: 'Cancelar',
          onPressed: () {
            Navigator.of(context).pop(); // Cerrar el diálogo
          },
        ),
        // hacer componente ElevatedButton
        ElevatedButton(
          onPressed: () async {
            final loginProvider = Provider.of<LoginProvider>(context, listen: false);
            await loginProvider.signOut();

            // Redirigir al usuario a la pantalla de inicio de sesión
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AwColors.red, // Color de fondo del botón
            foregroundColor: AwColors.white, // Color del texto
          ),
          child: const AwText(text: 'Cerrar sesión'),
        ),
      ],
    );
  }

  // Método para mostrar el diálogo en cualquier parte de tu app
  static void showLogOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const LogOutDialog();
      },
    );
  }
}
