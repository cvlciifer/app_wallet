import 'dart:developer';

import 'package:app_wallet/core/data_base_local/create_db.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

// ==========================
// Helpers
// ==========================

String? getUserEmail() => FirebaseAuth.instance.currentUser?.email;

Future<Database> _db() => DBHelper.instance.database;

// Normaliza la categoría igual que en Firestore (enum.toString().split('.') .last)
String _categoryToString(dynamic category) => category.toString().split('.').last;

// ==========================
// CRUD READ: Leer gastos del usuario autenticado (equivalente a getGastos de Firestore)
// Retorna una lista de mapas con las mismas keys: id, name, fecha, cantidad, tipo
// ==========================
Future<List<Map<String, dynamic>>> getGastosLocal() async {
  final email = getUserEmail();
  if (email == null) {
    log('Error: No se encontró el usuario autenticado');
    return [];
  }
  final db = await _db();
  final rows = await db.query(
    'gastos',
    columns: [
      'uid_gasto AS id',
      'nombre AS name',
      'fecha',
      'cantidad',
      'categoria AS tipo',
      'subcategoria AS subcategoria'
    ],
    where: 'uid_correo = ?',
    whereArgs: [email],
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
  final email = getUserEmail();
  if (email == null) {
    log('Error: No se encontró el usuario autenticado');
    return;
  }
  final db = await _db();
  await db.insert('gastos', {
    'uid_correo': email,
    'nombre': expense.title,
    'fecha': expense.date.millisecondsSinceEpoch,
    'cantidad': expense.amount,
    'categoria': _categoryToString(expense.category),
    'subcategoria': expense.subcategoryId,
  });

  // Opcional: encolar para sync si utilizas pending_ops
  // await DBHelper.instance.insertPending(...)
}

// ==========================
// CRUD DELETE: Eliminar un gasto
// ==========================
Future<void> deleteExpenseLocal(Expense expense) async {
  final email = getUserEmail();
  if (email == null) {
    log('Error: No se encontró el usuario autenticado');
    return;
  }
  final db = await _db();

  // Localizamos posibles coincidencias (puede haber varias)
  final rows = await db.query(
    'gastos',
    columns: ['uid_gasto'],
    where:
        'uid_correo = ? AND nombre = ? AND fecha = ? AND cantidad = ? AND categoria = ? AND (subcategoria IS ? OR subcategoria = ?)',
    whereArgs: [
      email,
      expense.title,
      expense.date.millisecondsSinceEpoch,
      expense.amount,
      _categoryToString(expense.category),
      expense.subcategoryId,
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
