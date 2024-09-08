import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:app_wallet/models/expense.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

// CRUD READ
Future<List> getGastos() async {
  List lisgastos = [];
  CollectionReference collectionReferenceGastos = db.collection('gastos');
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

// CRUD CREATE: función para guardar un gasto en Firebase
Future<void> createExpense(Expense expense) async {
  await db.collection('gastos').add({
    'name': expense.title,
    'fecha': Timestamp.fromDate(expense.date), // Convertir DateTime a Timestamp
    'cantidad': expense.amount,
    'tipo': expense.category
        .toString()
        .split('.')
        .last, // Guardar solo el valor de la categorías
  });
}

// CRUD DELETE
Future<void> deleteExpense(String name, DateTime fecha) async {
  try {
    // Search for the document with matching name and date
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('gastos')
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


Future<Map<String, dynamic>> getRandomConsejo() async {
  List<Map<String, dynamic>> consejos = [];
  CollectionReference collectionReferenceConsejos = db.collection('consejos');
  // Abre todos los datos de la colección
  QuerySnapshot queryConsejos = await collectionReferenceConsejos.get();
// Mensaje de depuración
  print('Número de documentos recuperados: ${queryConsejos.docs.length}');

  queryConsejos.docs.forEach((documento) {
    print('Documento: ${documento.data()}'); // Mensaje de depuración
    consejos.add(documento.data() as Map<String, dynamic>);
  });

  if (consejos.isEmpty) {
    return {}; // Retorna un mapa vacío si no hay consejos
  }

  // Retorna un consejo aleatorio de la lista
  final randomIndex = Random().nextInt(consejos.length);
  return consejos[randomIndex];
}
