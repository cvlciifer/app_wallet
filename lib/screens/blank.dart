/* import 'package:app_wallet/services_bd/firebase_Service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
           Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (ctx) => Expenses(), // Pantalla principal
              ),
              (route) => false, // Elimina todas las pantallas anteriores
            );
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
      Center(child:   FutureBuilder(
        future: getConsejos(),
        builder: ((context, snapshot){
          return ListView.builder(
            itemCount: snapshot.data?.length,
            itemBuilder:(context, index){
              return Text(snapshot.data?[index]['consejo']);
            } ,
          );
        }
        ),
        ),),
    
    );
  }
}
 */

import 'package:app_wallet/services_bd/firebase_Service.dart';
import 'package:flutter/material.dart';
import 'package:app_wallet/screens/expenses.dart'; // Importa la pantalla principal

class BlankScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla en Blanco'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (ctx) => Expenses(), // Pantalla principal
              ),
              (route) => false, // Elimina todas las pantallas anteriores
            );
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getRandomConsejo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar el consejo: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay consejos disponibles'));
          }

          var consejoData = snapshot.data!;
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(consejoData['consejo'] ?? 'Consejo no disponible'),
            ),
          );
        },
      ),
    );
  }
}
