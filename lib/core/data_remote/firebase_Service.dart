import 'dart:developer';

import 'package:app_wallet/library_section/main_library.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    log('Error: No se encontró el usuario autenticado');
    return lisgastos; // Retorna lista vacía si no hay usuario autenticado
  }

  // Referenciar la subcolección 'gastos' del usuario autenticado
  CollectionReference collectionReferenceGastos = db.collection('usuarios').doc(userEmail).collection('gastos');

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

// CRUD CREATE: Restaurar un gasto en la base de datos
Future<void> restoreExpense(Expense expense) async {
  String? userEmail = getUserEmail();

  if (userEmail == null) {
    log('Error: No se encontró el usuario autenticado para restaurar el gasto');
    return; // Salir si no hay usuario autenticado
  }

  try {
    log('Restaurando el gasto: ${expense.title}, ${expense.date}, ${expense.amount}, ${expense.category}');

    // Restaurar el gasto en la subcolección del usuario autenticado
    await db.collection('usuarios').doc(userEmail).collection('gastos').add({
      'name': expense.title,
      'fecha': Timestamp.fromDate(expense.date), // Convertir DateTime a Timestamp
      'cantidad': expense.amount,
      'tipo': expense.category.toString().split('.').last, // Guardar solo el valor de la categoría
    });

    log('Gasto restaurado correctamente.');
  } catch (error) {
    log('Error al restaurar el gasto: $error');
  }
}

// CRUD CREATE: Crear un nuevo gasto para el usuario autenticado
Future<void> createExpense(Expense expense) async {
  String? userEmail = getUserEmail();

  if (userEmail == null) {
    log('Error: No se encontró el usuario autenticado');
    return; // Salir si no hay usuario autenticado
  }

  // Referenciar la subcolección 'gastos' del usuario autenticado
  await db.collection('usuarios').doc(userEmail).collection('gastos').add({
    'name': expense.title,
    'fecha': Timestamp.fromDate(expense.date), // Convertir DateTime a Timestamp
    'cantidad': expense.amount,
    'tipo': expense.category.toString().split('.').last, // Guardar solo el valor de la categoría
  });
}

// CRUD DELETE: Eliminar un gasto del usuario autenticado
Future<void> deleteExpense(Expense expense) async {
  String? userEmail = getUserEmail();

  if (userEmail == null) {
    log('Error: No se encontró el usuario autenticado');
    return; // Salir si no hay usuario autenticado
  }

  try {
    log('Buscando el gasto para eliminar: ${expense.title}, ${expense.date}, ${expense.amount}, ${expense.category}');

    // Buscar el documento que coincide con el nombre, fecha, cantidad y tipo en la subcolección del usuario autenticado
    QuerySnapshot snapshot = await db
        .collection('usuarios')
        .doc(userEmail)
        .collection('gastos')
        .where('name', isEqualTo: expense.title)
        .where('fecha', isEqualTo: Timestamp.fromDate(expense.date)) // Convertir `expense.date` a Timestamp
        .where('cantidad', isEqualTo: expense.amount)
        .where('tipo', isEqualTo: expense.category.toString().split('.').last) // Coincidir con el valor de la categoría
        .get();

    log('Número de documentos encontrados para eliminar: ${snapshot.docs.length}');

    if (snapshot.docs.isNotEmpty) {
      // Eliminar cada documento encontrado
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        log('Gasto eliminado: ${doc.id}');
      }
    } else {
      log('No se encontró ningún gasto para eliminar.');
    }
  } catch (error) {
    log('Error al eliminar el gasto: $error');
  }
}

Future<Map<String, dynamic>> getConsejoDelDia() async {
  // Recupera todos los documentos de la colección 'consejos'
  QuerySnapshot queryConsejos = await db.collection('consejos').get();

  // Si no hay documentos, retorna un mapa vacío
  if (queryConsejos.docs.isEmpty) return {};

  // Convierte los documentos a una lista de mapas
  List<Map<String, dynamic>> consejos = queryConsejos.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

  // Genera una clave de fecha única (YYYYMMDD) y calcula un índice basado en el hash
  int index = DateTime.now().toIso8601String().substring(0, 10).hashCode % consejos.length;

  // Retorna el consejo del día
  return consejos[index];
}
