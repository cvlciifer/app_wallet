import 'package:flutter/material.dart';
import 'package:app_wallet/services_bd/firebase_service.dart';

Future<void> showConsejoDialog(BuildContext context) async {
  try {
    var consejo = await getRandomConsejo();
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
  } catch (e) {
    print('Error al obtener consejo: $e');
  }
}
