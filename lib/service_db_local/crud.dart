import 'package:app_wallet/service_db_local/create_db.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_wallet/library/main_library.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

// Helpers

String? getUserEmail() => FirebaseAuth.instance.currentUser?.email;
String? getUserUid() => FirebaseAuth.instance.currentUser?.uid;

Future<Database> _db() => DBHelper.instance.database;

// Normaliza la categoría igual que en Firestore (enum.toString().split('.') .last)
String _categoryToString(dynamic category) => category.toString().split('.').last;

// --- UTIL: intenta ejecutar query usando uid_usuario, si no devuelve filas intenta con uid_correo (email)
Future<List<Map<String, dynamic>>> _queryGastosByUidOrEmail(
    Database db, String? uid, String? email) async {
  if (uid != null) {
    final rowsByUid = await db.query(
      'gastos',
      columns: ['uid_gasto AS id', 'nombre AS name', 'fecha', 'cantidad', 'categoria AS tipo'],
      where: 'uid_usuario = ?',
      whereArgs: [uid],
      orderBy: 'fecha DESC',
    );
    if (rowsByUid.isNotEmpty) return rowsByUid;
  }

  // fallback a uid_correo (compatibilidad con esquema antiguo)
  if (email != null) {
    final rowsByEmail = await db.query(
      'gastos',
      columns: ['uid_gasto AS id', 'nombre AS name', 'fecha', 'cantidad', 'categoria AS tipo'],
      where: 'uid_correo = ?',
      whereArgs: [email],
      orderBy: 'fecha DESC',
    );
    return rowsByEmail;
  }

  return [];
}

// CRUD READ: Leer gastos del usuario autenticado (equivalente a getGastos de Firestore)
// Retorna una lista de mapas con las mismas keys: id, name, fecha, cantidad, tipo
Future<List<Map<String, dynamic>>> getGastosLocal() async {
  final email = getUserEmail();
  final uid = getUserUid();

  if (email == null && uid == null) {
    print('Error: No se encontró el usuario autenticado');
    return [];
  }

  final db = await _db();
  // aseguro BD creada
  await DBHelper.instance.database;

  return await _queryGastosByUidOrEmail(db, uid, email);
}

// CRUD CREATE: Restaurar un gasto (equivalente a restoreExpense)
Future<void> restoreExpenseLocal(Expense expense) async {
  await _insertExpense(expense);
}

// CRUD CREATE: Crear un nuevo gasto (equivalente a createExpense)
Future<void> createExpenseLocal(Expense expense) async {
  await _insertExpense(expense);
}

Future<void> _insertExpense(Expense expense) async {
  final email = getUserEmail();
  final uid = getUserUid();

  if (email == null && uid == null) {
    print('Error: No se encontró el usuario autenticado');
    return;
  }

  final db = await _db();
  // Asegurar BD (por si)
  await DBHelper.instance.database;

  final record = <String, dynamic>{
    'nombre': expense.title,
    'fecha': expense.date.millisecondsSinceEpoch,
    'cantidad': expense.amount,
    'categoria': _categoryToString(expense.category),
    // opcionales: created_at para sync
    'created_at': DateTime.now().millisecondsSinceEpoch,
  };

  // Preferir uid_usuario si existe (esquema recomendado)
  if (uid != null) {
    record['uid_usuario'] = uid;
  } else if (email != null) {
    // compatibilidad con esquema antiguo
    record['uid_correo'] = email;
  }

  await db.insert('gastos', record);
}

// CRUD DELETE: Eliminar un gasto 
Future<void> deleteExpenseLocal(Expense expense) async {
  final email = getUserEmail();
  final uid = getUserUid();

  if (email == null && uid == null) {
    print('Error: No se encontró el usuario autenticado');
    return;
  }

  final db = await _db();
  // Asegurar BD
  await DBHelper.instance.database;

  // Primero intentamos eliminar usando uid_usuario (si existe)
  if (uid != null) {
    final rows = await db.query(
      'gastos',
      columns: ['uid_gasto'],
      where: 'uid_usuario = ? AND nombre = ? AND fecha = ? AND cantidad = ? AND categoria = ?',
      whereArgs: [
        uid,
        expense.title,
        expense.date.millisecondsSinceEpoch,
        expense.amount,
        _categoryToString(expense.category),
      ],
    );

    if (rows.isNotEmpty) {
      for (final r in rows) {
        final id = r['uid_gasto'] as int;
        await db.delete('gastos', where: 'uid_gasto = ?', whereArgs: [id]);
        print('Gasto eliminado (por uid_usuario): $id');
      }
      return;
    }
  }

  // Fallback: intentar con uid_correo (email)
  if (email != null) {
    final rows = await db.query(
      'gastos',
      columns: ['uid_gasto'],
      where: 'uid_correo = ? AND nombre = ? AND fecha = ? AND cantidad = ? AND categoria = ?',
      whereArgs: [
        email,
        expense.title,
        expense.date.millisecondsSinceEpoch,
        expense.amount,
        _categoryToString(expense.category),
      ],
    );

    if (rows.isEmpty) {
      print('No se encontró ningún gasto para eliminar.');
      return;
    }

    for (final r in rows) {
      final id = r['uid_gasto'] as int;
      await db.delete('gastos', where: 'uid_gasto = ?', whereArgs: [id]);
      print('Gasto eliminado (por uid_correo): $id');
    }
    return;
  }

  print('No se encontró ningún gasto para eliminar.');
}
