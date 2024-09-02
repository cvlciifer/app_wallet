import 'package:flutter/material.dart';
import 'package:app_wallet/screens/expenses.dart'; // Importa la pantalla principal

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
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (ctx) => Expenses(), // Pantalla principal
              ),
              (route) => false, // Elimina todas las pantallas anteriores
            );
          },
          child: Text('Volver a la Pantalla Principal'),
        ),
      ),
    );
  }
}
