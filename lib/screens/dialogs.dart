import 'package:flutter/material.dart';
import 'package:app_wallet/services_bd/firebase_service.dart'; // Importa el servicio de Firebase

Future<void> showConsejoDialog(BuildContext context) async {
  try {
    var consejo = await getRandomConsejo();
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            content: consejo.isNotEmpty
                ? Text(consejo['consejo'] ?? 'Consejo no disponible')
                : const Text('No hay consejos disponibles'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    }
  } catch (error) {
    print('Error al cargar el consejo: $error');
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Error al cargar el consejo: $error'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    }
  }
}
