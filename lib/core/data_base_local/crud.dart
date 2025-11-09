import 'dart:developer';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

String? getUserEmail() => FirebaseAuth.instance.currentUser?.email;

Future<Database> _db() => DBHelper.instance.database;

String _categoryToString(dynamic category) => category.toString().split('.').last;

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

  return rows;
}

Future<void> restoreExpenseLocal(Expense expense) async {
  await _insertExpense(expense);
}

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
}

Future<void> deleteExpenseLocal(Expense expense) async {
  final email = getUserEmail();
  if (email == null) {
    log('Error: No se encontró el usuario autenticado');
    return;
  }
  final db = await _db();

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
