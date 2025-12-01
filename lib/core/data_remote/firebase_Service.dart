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

/// Crea o agrega una entrada de ingreso en Firestore bajo la colección
/// usuarios/{email}/ingresos.
Future<void> createIncomeEntry(DateTime date, int ingresoFijo, int ingresoImprevisto) async {
  String? userEmail = getUserEmail();
  if (userEmail == null) {
    log('createIncomeEntry: no hay usuario autenticado');
    return;
  }

  try {
    await db.collection('usuarios').doc(userEmail).collection('ingresos').add({
      'fecha': Timestamp.fromDate(date),
      'ingreso_fijo': ingresoFijo,
      'ingreso_imprevisto': ingresoImprevisto,
    });
    log('Ingreso creado en Firestore: $date -> $ingresoFijo (imprevisto: $ingresoImprevisto)');
  } catch (e) {
    log('Error al crear ingreso en Firestore: $e');
  }
}

/// Upsert (create or update) an income entry for the given date (1er día del mes).
Future<bool> upsertIncomeEntry(DateTime date, int ingresoFijo, int? ingresoImprevisto, {String? docId}) async {
  String? userEmail = getUserEmail();
  if (userEmail == null) {
    log('upsertIncomeEntry: no hay usuario autenticado');
    return false;
  }

  try {
    final collection = db.collection('usuarios').doc(userEmail).collection('ingresos');
    final id = docId ?? '${date.year}${date.month.toString().padLeft(2, '0')}';
    final docRef = collection.doc(id);
    final ts = Timestamp.fromDate(date);

    final snapshot = await docRef.get();
    final existingImprev = snapshot.exists ? (snapshot.data()?['ingreso_imprevisto'] ?? 0) : 0;
    final ingresoImprev = ingresoImprevisto ?? existingImprev;
    final ingresoTotal = ingresoFijo + ingresoImprev;

    final payload = {
      'fecha': ts,
      'ingreso_fijo': ingresoFijo,
      'ingreso_imprevisto': ingresoImprev,
      'ingreso_total': ingresoTotal,
      'id': id,
    };

    if (snapshot.exists) {
      await docRef.update(payload);
      log('Ingreso actualizado en Firestore para id=$id fecha=$date');
    } else {
      await docRef.set(payload);
      log('Ingreso creado en Firestore para id=$id fecha=$date');
    }
    return true;
  } catch (e, st) {
    log('Error en upsertIncomeEntry: $e\n$st');
    return false;
  }
}

/// Obtiene todos los ingresos del usuario desde Firestore.
/// Devuelve una lista de mapas con claves: 'id', 'fecha' (Timestamp o int),
/// 'ingreso_fijo', 'ingreso_imprevisto', 'ingreso_total'
Future<List<Map<String, dynamic>>> getAllIncomesFromFirestore() async {
  final List<Map<String, dynamic>> results = [];
  String? userEmail = getUserEmail();
  if (userEmail == null) {
    log('getAllIncomesFromFirestore: no user email');
    return results;
  }

  try {
    final collection = db.collection('usuarios').doc(userEmail).collection('ingresos');
    final snapshot = await collection.get();
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      results.add({
        'id': doc.id,
        'fecha': data['fecha'],
        'ingreso_fijo': data['ingreso_fijo'] ?? 0,
        'ingreso_imprevisto': data['ingreso_imprevisto'] ?? 0,
        'ingreso_total': data['ingreso_total'] ?? ((data['ingreso_fijo'] ?? 0) + (data['ingreso_imprevisto'] ?? 0)),
      });
    }
  } catch (e, st) {
    log('getAllIncomesFromFirestore error: $e\n$st');
  }

  return results;
}
