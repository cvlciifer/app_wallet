// lib/screens/blank_screen.dart

import 'package:flutter/material.dart';

class BlankScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pantalla en Blanco'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Regresar a la pantalla anterior
          },
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/main', // Ruta de la pantalla principal
              (route) => false, // Elimina todas las pantallas anteriores
            );
          },
          child: Text('Volver a la Pantalla Principal'),
        ),
      ),
    );
  }
}
