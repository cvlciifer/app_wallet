import 'dart:developer';
import 'package:app_wallet/library_section/main_library.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

String? getUserEmail() {
  return FirebaseAuth.instance.currentUser?.email;
}

Future<List> getGastos() async {
  List lisgastos = [];
  String? userEmail = getUserEmail();

  if (userEmail == null) {
    log('Error: No se encontró el usuario autenticado');
    return lisgastos;
  }

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

Future<void> restoreExpense(Expense expense) async {
  String? userEmail = getUserEmail();

  if (userEmail == null) {
    log('Error: No se encontró el usuario autenticado para restaurar el gasto');
    return;
  }

  try {
    log('Restaurando el gasto: ${expense.title}, ${expense.date}, ${expense.amount}, ${expense.category}');

    await db.collection('usuarios').doc(userEmail).collection('gastos').add({
      'name': expense.title,
      'fecha': Timestamp.fromDate(expense.date),
      'cantidad': expense.amount,
      'tipo': expense.category.toString().split('.').last,
    });

    log('Gasto restaurado correctamente.');
  } catch (error) {
    log('Error al restaurar el gasto: $error');
  }
}

Future<void> createExpense(Expense expense) async {
  String? userEmail = getUserEmail();

  if (userEmail == null) {
    log('Error: No se encontró el usuario autenticado');
    return;
  }

  await db.collection('usuarios').doc(userEmail).collection('gastos').add({
    'name': expense.title,
    'fecha': Timestamp.fromDate(expense.date),
    'cantidad': expense.amount,
    'tipo': expense.category.toString().split('.').last,
  });
}

Future<void> deleteExpense(Expense expense) async {
  String? userEmail = getUserEmail();

  if (userEmail == null) {
    log('Error: No se encontró el usuario autenticado');
    return;
  }

  try {
    log('Buscando el gasto para eliminar: ${expense.title}, ${expense.date}, ${expense.amount}, ${expense.category}');

    QuerySnapshot snapshot = await db
        .collection('usuarios')
        .doc(userEmail)
        .collection('gastos')
        .where('name', isEqualTo: expense.title)
        .where('fecha', isEqualTo: Timestamp.fromDate(expense.date))
        .where('cantidad', isEqualTo: expense.amount)
        .where('tipo', isEqualTo: expense.category.toString().split('.').last)
        .get();

    log('Número de documentos encontrados para eliminar: ${snapshot.docs.length}');

    if (snapshot.docs.isNotEmpty) {
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
  QuerySnapshot queryConsejos = await db.collection('consejos').get();

  if (queryConsejos.docs.isEmpty) return {};

  List<Map<String, dynamic>> consejos = queryConsejos.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

  int index = DateTime.now().toIso8601String().substring(0, 10).hashCode % consejos.length;

  return consejos[index];
}
