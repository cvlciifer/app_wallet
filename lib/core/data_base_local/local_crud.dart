import 'dart:developer';
import '../sync_service/sync_service.dart';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

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
  final uid = await getUserUid();
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
            subcategoryId: row['subcategoria'] as String?,
            syncStatus: row['sync_status'] != null ? SyncStatus.values[row['sync_status'] as int] : SyncStatus.synced,
          ))
      .toList();
}

Future<String?> getUserUid() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null && uid.isNotEmpty) return uid;
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('userUid') ?? prefs.getString('lastUserUid');
    return saved;
  } catch (_) {
    return null;
  }
}

Future<String?> getUserEmail() async {
  final email = FirebaseAuth.instance.currentUser?.email;
  if (email != null && email.isNotEmpty) return email;
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  } catch (_) {
    return null;
  }
}

Future<Database> _db() => DBHelper.instance.database;

String _categoryToString(dynamic category) => category.toString().split('.').last;

Future<void> _ensureUserExists() async {
  final uid = await getUserUid();
  final email = await getUserEmail();

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
    await db.insert('usuarios', {
      'uid': uid,
      'correo': email,
    });
    log('Usuario insertado en BD local: $uid');
  }
}

Future<List<Map<String, dynamic>>> getGastosLocal() async {
  final uid = await getUserUid();
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

  return rows;
}

Future<void> restoreExpenseLocal(Expense expense) async {
  await insertExpenseImpl(expense);
}

Future<void> createExpenseLocal(Expense expense) async {
  await insertExpenseImpl(expense);
}

Future<void> insertExpenseImpl(Expense expense) async {
  final uid = await getUserUid();
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
    'subcategoria': expense.subcategoryId,
    'sync_status': expense.syncStatus.index,
    'id': expense.id,
  });
}

Future<void> updateExpenseImpl(Expense expense) async {
  final uid = await getUserUid();
  if (uid == null) return;
  final db = await _db();
  await db.update(
    'gastos',
    {
      'nombre': expense.title,
      'fecha': expense.date.millisecondsSinceEpoch,
      'cantidad': expense.amount,
      'categoria': _categoryToString(expense.category),
      'subcategoria': expense.subcategoryId,
      'sync_status': expense.syncStatus.index,
    },
    where: 'id = ? AND uid_correo = ?',
    whereArgs: [expense.id, uid],
  );
}

Future<void> updateSyncStatusImpl(String expenseId, SyncStatus status) async {
  final uid = await getUserUid();
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
  final uid = await getUserUid();
  if (uid == null) return;
  final db = await _db();
  await db.delete('gastos', where: 'id = ? AND uid_correo = ?', whereArgs: [expenseId, uid]);
}

Future<List<Expense>> getPendingExpensesImpl() async {
  final uid = await getUserUid();
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
            subcategoryId: row['subcategoria'] as String?,
            syncStatus: SyncStatus.values[row['sync_status'] as int],
          ))
      .toList();
}

Future<void> replaceAllExpensesImpl(List<Expense> expenses) async {
  final uid = await getUserUid();
  if (uid == null) return;
  final db = await _db();
  await db.delete('gastos', where: 'uid_correo = ?', whereArgs: [uid]);
  for (final expense in expenses) {
    await insertExpenseImpl(expense);
  }
}

Category _mapCategory(String tipo) {
  for (final c in Category.values) {
    final enumName = c.toString().split('.').last;
    if (enumName == tipo) return c;
    if (c.displayName == tipo) return c;
  }

  return Category.comidaBebida;
}

Future<void> deleteExpenseLocal(Expense expense) async {
  final uid = await getUserUid();
  if (uid == null) {
    log('Error: No se encontró el usuario autenticado');
    return;
  }
  final db = await _db();

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

Future<void> updateExpenseLocal(int uidGasto, Expense expense) async {
  final uid = await getUserUid();
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
