import 'dart:developer';

import 'package:app_wallet/service_db_local/create_db.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_wallet/library/main_library.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

// ==========================
// Helpers
// ==========================

String? getUserUid() => FirebaseAuth.instance.currentUser?.uid;

String? getUserEmail() => FirebaseAuth.instance.currentUser?.email;

Future<Database> _db() => DBHelper.instance.database;

// Normaliza la categoría igual que en Firestore (enum.toString().split('.') .last)
String _categoryToString(dynamic category) => category.toString().split('.').last;

// Verifica que el usuario esté registrado en la base de datos local
Future<void> _ensureUserExists() async {
  final uid = getUserUid();
  final email = getUserEmail();
  
  if (uid == null || email == null) {
    throw Exception('No se encontró el usuario autenticado');
  }
  
  final db = await _db();
  final existingUser = await db.query(
    'usuarios',
    where: 'uid = ?',
    whereArgs: [uid],
    limit: 1,
  );
  
  if (existingUser.isEmpty) {
    // El usuario no existe en la BD local, lo insertamos
    await db.insert('usuarios', {
      'uid': uid,
      'correo': email,
    });
    log('Usuario insertado en BD local: $uid');
  }
}

// ==========================
// CRUD READ: Leer gastos del usuario autenticado (equivalente a getGastos de Firestore)
// Retorna una lista de mapas con las mismas keys: id, name, fecha, cantidad, tipo
// ==========================
Future<List<Map<String, dynamic>>> getGastosLocal() async {
  final uid = getUserUid();
  if (uid == null) {
    log('Error: No se encontró el usuario autenticado');
    return [];
  }
  final db = await _db();
  final rows = await db.query(
    'gastos',
    columns: ['uid_gasto AS id', 'nombre AS name', 'fecha', 'cantidad', 'categoria AS tipo'],
    where: 'uid_correo = ?',
    whereArgs: [uid],
    orderBy: 'fecha DESC',
  );

  // fecha en SQLite está en ms epoch. Si arriba quieres imitar Firestore Timestamp, puedes convertir aquí
  // pero para mantener "lo mismo" dejamos el entero de ms. Si necesitas DateTime usa DateTime.fromMillisecondsSinceEpoch(row['fecha'])
  return rows;
}

// ==========================
// CRUD CREATE: Restaurar un gasto (equivalente a restoreExpense)
// ==========================
Future<void> restoreExpenseLocal(Expense expense) async {
  await _insertExpense(expense);
}

// ==========================
// CRUD CREATE: Crear un nuevo gasto (equivalente a createExpense)
// ==========================
Future<void> createExpenseLocal(Expense expense) async {
  await _insertExpense(expense);
}

Future<void> _insertExpense(Expense expense) async {
  final uid = getUserUid();
  if (uid == null) {
    log('Error: No se encontró el usuario autenticado');
    return;
  }
  
  // Asegurar que el usuario existe en la BD local
  await _ensureUserExists();
  
  final db = await _db();
  await db.insert('gastos', {
    'uid_correo': uid,
    'nombre': expense.title,
    'fecha': expense.date.millisecondsSinceEpoch,
    'cantidad': expense.amount,
    'categoria': _categoryToString(expense.category),
  });

  // Opcional: encolar para sync si utilizas pending_ops
  // await DBHelper.instance.insertPending(...)
}

// ==========================
// CRUD DELETE: Eliminar un gasto 
// ==========================
Future<void> deleteExpenseLocal(Expense expense) async {
  final uid = getUserUid();
  if (uid == null) {
    log('Error: No se encontró el usuario autenticado');
    return;
  }
  final db = await _db();

  // Localizamos posibles coincidencias (puede haber varias)
  final rows = await db.query(
    'gastos',
    columns: ['uid_gasto'],
    where: 'uid_correo = ? AND nombre = ? AND fecha = ? AND cantidad = ? AND categoria = ?',
    whereArgs: [
      uid,
      expense.title,
      expense.date.millisecondsSinceEpoch,
      expense.amount,
      _categoryToString(expense.category),
    ],
  );

  if (rows.isEmpty) {
    log('No se encontró ningún gasto para eliminar.');
    return;
  }

  for (final r in rows) {
    final id = r['uid_gasto'] as int;
    await db.delete('gastos', where: 'uid_gasto = ?', whereArgs: [id]);
    log('Gasto eliminado: $id');
  }
}

// ==========================
// CRUD UPDATE: Editar un gasto existente
// ==========================
Future<void> updateExpenseLocal(int uidGasto, Expense expense) async {
  final uid = getUserUid();
  if (uid == null) {
    log('Error: No se encontró el usuario autenticado');
    return;
  }

  final db = await _db();

  await db.update(
    'gastos',
    {
      'uid_correo': uid,
      'nombre': expense.title,
      'fecha': expense.date.millisecondsSinceEpoch,
      'cantidad': expense.amount,
      'categoria': _categoryToString(expense.category),
    },
    where: 'uid_gasto = ? AND uid_correo = ?',
    whereArgs: [uidGasto, uid],
  );
}

