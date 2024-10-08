import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:app_wallet/models/expense.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_wallet/models/expense.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

// Obtener el correo del usuario autenticado
String? getUserEmail() {
  return FirebaseAuth.instance.currentUser?.email;
}

// CRUD READ: Leer gastos del usuario autenticado
Future<List> getGastos() async {
  List lisgastos = [];
  String? userEmail = getUserEmail();

  if (userEmail == null) {
    print('Error: No se encontró el usuario autenticado');
    return lisgastos; // Retorna lista vacía si no hay usuario autenticado
  }

  // Referenciar la subcolección 'gastos' del usuario autenticado
  CollectionReference collectionReferenceGastos =
      db.collection('usuarios').doc('Gastos').collection(userEmail);

  QuerySnapshot queryGastos = await collectionReferenceGastos.get();

  for (var doc in queryGastos.docs) {
    final Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
    final gastos = {
      'id': doc.id,
      'name': docData['name'],
      'fecha': docData['fecha'],
      'cantidad': docData['cantidad'],
      'tipo': docData['tipo'],
    };
    lisgastos.add(gastos);
  }

  return lisgastos;
}

// CRUD CREATE: Crear un nuevo gasto para el usuario autenticado
Future<void> createExpense(Expense expense) async {
  String? userEmail = getUserEmail();

  if (userEmail == null) {
    print('Error: No se encontró el usuario autenticado');
    return; // Salir si no hay usuario autenticado
  }

  // Referenciar la subcolección 'gastos' del usuario autenticado
  await db.collection('usuarios').doc('Gastos').collection(userEmail).add({
    'name': expense.title,
    'fecha': Timestamp.fromDate(expense.date), // Convertir DateTime a Timestamp
    'cantidad': expense.amount,
    'tipo': expense.category
        .toString()
        .split('.')
        .last, // Guardar solo el valor de la categoría
  });
}

// CRUD DELETE: Eliminar un gasto del usuario autenticado
Future<void> deleteExpense(String name, DateTime fecha) async {
  String? userEmail = getUserEmail();

  if (userEmail == null) {
    print('Error: No se encontró el usuario autenticado');
    return; // Salir si no hay usuario autenticado
  }

  try {
    // Buscar el documento que coincide con el nombre y la fecha en la subcolección del usuario autenticado
    QuerySnapshot snapshot = await db
        .collection('usuarios')
        .doc('gastos')
        .collection(userEmail)
        .where('name', isEqualTo: name)
        .where('fecha', isEqualTo: Timestamp.fromDate(fecha))
        .get();

    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        print('Gasto eliminado: ${doc.id}');
      }
    } else {
      print('No se encontró ningún gasto para eliminar.');
    }
  } catch (error) {
    print('Error al eliminar el gasto: $error');
  }
}

Future<Map<String, dynamic>> getConsejoDelDia() async {
  List<Map<String, dynamic>> consejos = [];
  CollectionReference collectionReferenceConsejos = db.collection('consejos');

  // Abre todos los datos de la colección
  QuerySnapshot queryConsejos = await collectionReferenceConsejos.get();

  // Mensaje de depuración
  print('Número de documentos recuperados: ${queryConsejos.docs.length}');

  // Agrega los documentos a la lista de consejos
  queryConsejos.docs.forEach((documento) {
    print('Documento: ${documento.data()}'); // Mensaje de depuración
    consejos.add(documento.data() as Map<String, dynamic>);
  });

  if (consejos.isEmpty) {
    return {}; // Retorna un mapa vacío si no hay consejos
  }

  // Obtén la fecha actual
  DateTime now = DateTime.now();

  // Convierte la fecha a un formato único (por ejemplo, YYYYMMDD)
  String fechaKey =
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

  // Calcula un índice usando un hash simple de la fecha
  int index = fechaKey.hashCode % consejos.length;

  // Retorna el consejo del día
  return consejos[index];
}
