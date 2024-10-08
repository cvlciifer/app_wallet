import 'package:flutter/material.dart';
import 'package:app_wallet/screens/logIn.dart';

class LogOutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Vas a cerrar sesión',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Row(
        children: [
           Icon(
            Icons.warning,
            color: Colors.orange,
            size: 24.0,
          ),
           SizedBox(width: 10),
           Expanded(
            child: Text(
              '¿Estás seguro?',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0), // Bordes redondeados
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Cerrar el diálogo
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            // Aquí podrías agregar cualquier acción para limpiar los datos de sesión si es necesario
            // Por ejemplo, limpiar el token o las preferencias del usuario.

            // Redirigir al usuario a la pantalla de inicio de sesión
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
            );
          },
          child:const Text('Cerrar sesión'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // Color de fondo del botón
            foregroundColor: Colors.white, // Color del texto
          ),
        ),
      ],
    );
  }

  // Método para mostrar el diálogo en cualquier parte de tu app
  static void showLogOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LogOutDialog();
      },
    );
  }
}
