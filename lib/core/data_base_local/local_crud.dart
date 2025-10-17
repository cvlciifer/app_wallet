import 'dart:developer';
import 'package:app_wallet/core/data_base_local/create_db.dart';
import '../../home_section/presentation/new_expense/presentation/models/expense.dart';
import '../sync_service/sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

// Clase para exponer los métodos de la base local como instancia
class LocalCrud {
  Future<List<Expense>> getAllExpenses() => getAllExpensesImpl();
  Future<void> insertExpense(Expense expense) => insertExpenseImpl(expense);
  Future<void> updateExpense(Expense expense) => updateExpenseImpl(expense);
  Future<void> updateSyncStatus(String expenseId, SyncStatus status) => updateSyncStatusImpl(expenseId, status);
  Future<void> deleteExpense(String expenseId, {bool localOnly = false}) =>
      deleteExpenseImpl(expenseId, localOnly: localOnly);
  Future<List<Expense>> getPendingExpenses() => getPendingExpensesImpl();
  Future<void> replaceAllExpenses(List<Expense> expenses) => replaceAllExpensesImpl(expenses);
}

Future<List<Expense>> getAllExpensesImpl() async {
  final uid = getUserUid();
  if (uid == null) return [];
  final db = await _db();
  final rows = await db.query('gastos', where: 'uid_correo = ?', whereArgs: [uid]);
  return rows
      .map((row) => Expense(
            id: row['id'] as String,
            title: row['nombre'] as String,
            amount: (row['cantidad'] as num).toDouble(),
            date: DateTime.fromMillisecondsSinceEpoch(row['fecha'] as int),
            category: _mapCategory(row['categoria'] as String),
            syncStatus: row['sync_status'] != null ? SyncStatus.values[row['sync_status'] as int] : SyncStatus.synced,
          ))
      .toList();
}

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
  await insertExpenseImpl(expense);
}

// ==========================
// CRUD CREATE: Crear un nuevo gasto (equivalente a createExpense)
// ==========================
Future<void> createExpenseLocal(Expense expense) async {
  await insertExpenseImpl(expense);
}

Future<void> insertExpenseImpl(Expense expense) async {
  final uid = getUserUid();
  if (uid == null) {
    log('Error: No se encontró el usuario autenticado');
    return;
  }
  await _ensureUserExists();
  final db = await _db();
  await db.insert('gastos', {
    'uid_correo': uid,
    'nombre': expense.title,
    'fecha': expense.date.millisecondsSinceEpoch,
    'cantidad': expense.amount,
    'categoria': _categoryToString(expense.category),
    'sync_status': expense.syncStatus.index,
    'id': expense.id,
  });
}

Future<void> updateExpenseImpl(Expense expense) async {
  final uid = getUserUid();
  if (uid == null) return;
  final db = await _db();
  await db.update(
    'gastos',
    {
      'nombre': expense.title,
      'fecha': expense.date.millisecondsSinceEpoch,
      'cantidad': expense.amount,
      'categoria': _categoryToString(expense.category),
      'sync_status': expense.syncStatus.index,
    },
    where: 'id = ? AND uid_correo = ?',
    whereArgs: [expense.id, uid],
  );
}

Future<void> updateSyncStatusImpl(String expenseId, SyncStatus status) async {
  final uid = getUserUid();
  if (uid == null) return;
  final db = await _db();
  await db.update(
    'gastos',
    {'sync_status': status.index},
    where: 'id = ? AND uid_correo = ?',
    whereArgs: [expenseId, uid],
  );
}

Future<void> deleteExpenseImpl(String expenseId, {bool localOnly = false}) async {
  final uid = getUserUid();
  if (uid == null) return;
  final db = await _db();
  await db.delete('gastos', where: 'id = ? AND uid_correo = ?', whereArgs: [expenseId, uid]);
}

Future<List<Expense>> getPendingExpensesImpl() async {
  final uid = getUserUid();
  if (uid == null) return [];
  final db = await _db();
  final rows =
      await db.query('gastos', where: 'uid_correo = ? AND sync_status != ?', whereArgs: [uid, SyncStatus.synced.index]);
  return rows
      .map((row) => Expense(
            id: row['id'] as String,
            title: row['nombre'] as String,
            amount: (row['cantidad'] as num).toDouble(),
            date: DateTime.fromMillisecondsSinceEpoch(row['fecha'] as int),
            category: _mapCategory(row['categoria'] as String),
            syncStatus: SyncStatus.values[row['sync_status'] as int],
          ))
      .toList();
}

Future<void> replaceAllExpensesImpl(List<Expense> expenses) async {
  final uid = getUserUid();
  if (uid == null) return;
  final db = await _db();
  await db.delete('gastos', where: 'uid_correo = ?', whereArgs: [uid]);
  for (final expense in expenses) {
    await insertExpenseImpl(expense);
  }
}

Category _mapCategory(String tipo) {
  switch (tipo) {
    case 'trabajo':
      return Category.trabajo;
    case 'ocio':
      return Category.ocio;
    case 'comida':
      return Category.comida;
    case 'viajes':
      return Category.viajes;
    case 'salud':
      return Category.salud;
    case 'servicios':
      return Category.servicios;
    default:
      return Category.comida;
  }
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
