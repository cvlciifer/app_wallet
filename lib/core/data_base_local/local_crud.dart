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
  Future<Map<String, int>> getGastosCountByUid() => getGastosCountByUidImpl();
}

Future<List<Expense>> getAllExpensesImpl() async {
  var uid = await getUserUid();
  if (uid == null) {
    // Intentar resolver UID usando el email persistido en la BD local
    uid = await _resolveUidFromSavedEmail();
  }
  if (uid == null) {
    log('getAllExpensesImpl: no se pudo resolver UID, devolviendo lista vacía');
    return [];
  }
  final db = await _db();
  final rows = await db.query('gastos', where: 'uid_correo = ?', whereArgs: [uid]);
  log('getAllExpensesImpl: uid=$uid, filas encontradas=${rows.length}');
  // Si no encontramos filas para el UID resuelto, intentar usar un UID alternativo
  // que tenga gastos en la BD local (esto maneja casos donde las inserciones
  // se guardaron bajo un uid distinto al que ahora resolvemos).
  if (rows.isEmpty) {
    try {
      final alt = await getGastosCountByUidImpl();
      if (alt.isNotEmpty) {
        // Elegir el UID con más filas
        final altUid = alt.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        if (altUid != uid) {
          log('getAllExpensesImpl: no hay filas para uid=$uid, usando uid alternativo=$altUid (counts=$alt)');
          final altRows = await db.query('gastos', where: 'uid_correo = ?', whereArgs: [altUid]);
          if (altRows.isNotEmpty) {
            log('getAllExpensesImpl: filas encontradas para uid alternativo=$altUid -> ${altRows.length}');
            return altRows
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
        }
      }
    } catch (e, st) {
      log('getAllExpensesImpl: fallback por uid alternativo falló: $e\n$st');
    }
  }
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
    if (saved != null && saved.isNotEmpty) return saved;
    // si no está en prefs, intentamos resolver con el email guardado
    final savedEmail = prefs.getString('userEmail');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      final usuario = await DBHelper.instance.getUsuarioPorEmail(savedEmail);
      if (usuario != null && usuario['uid'] != null) {
        final resolved = usuario['uid'] as String;
        log('getUserUid: resuelto desde email guardado -> $resolved');
        return resolved;
      }
    }
    // Si aún no tenemos UID, buscar un UID fallback persistido localmente.
    final fallback = prefs.getString('localFallbackUid');
    if (fallback != null && fallback.isNotEmpty) {
      log('getUserUid: usando localFallbackUid -> $fallback');
      return fallback;
    }
    // Crear un UID local consistente para permitir operaciones offline persistentes.
    final newLocalUid = Uuid().v4();
    await prefs.setString('localFallbackUid', newLocalUid);
    // Guardar en la tabla usuarios para satisfacer la FK y permitir consultas.
    try {
      final emailForUser = (prefs.getString('userEmail') ?? '${newLocalUid}@local').toLowerCase();
      await DBHelper.instance.upsertUsuario(uid: newLocalUid, correo: emailForUser);
      log('getUserUid: creado localFallbackUid y usuario local -> $newLocalUid (email: $emailForUser)');
    } catch (e, st) {
      log('getUserUid: error insertando usuario placeholder: $e\n$st');
    }
    return newLocalUid;
  } catch (e, st) {
    log('getUserUid error: $e\n$st');
    return null;
  }
}

Future<String?> _resolveUidFromSavedEmail() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('userEmail');
    if (savedEmail == null || savedEmail.isEmpty) return null;
    final usuario = await DBHelper.instance.getUsuarioPorEmail(savedEmail);
    if (usuario != null && usuario['uid'] != null) {
      final uid = usuario['uid'] as String;
      log('UID resuelto por email guardado: $uid (email: $savedEmail)');
      return uid;
    }
  } catch (e, st) {
    log('Error resolviendo UID desde email guardado: $e\n$st');
  }
  return null;
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
  if (uid == null) {
    throw Exception('No se encontró el usuario autenticado (uid)');
  }

  final email = await getUserEmail();
  // If we don't have a real email (offline scenario), use a placeholder
  // based on uid so that the 'usuarios' table can be populated and the
  // foreign key constraint on 'gastos.uid_correo' is satisfied.
  final emailToSave = (email != null && email.isNotEmpty) ? email : '${uid}@local';

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
      'correo': emailToSave,
    });
    log('Usuario insertado en BD local: $uid (correo: $emailToSave)');
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

/// Devuelve un mapa { uid_correo: count } para diagnosticar si existen gastos
/// asociados a UIDs distintos en la BD local.
Future<Map<String, int>> getGastosCountByUidImpl() async {
  final db = await _db();
  final rows = await db.rawQuery('SELECT uid_correo, COUNT(*) as cnt FROM gastos GROUP BY uid_correo');
  final Map<String, int> result = {};
  for (final r in rows) {
    final uid = r['uid_correo'] as String? ?? '<null>';
    final cnt = (r['cnt'] as int?) ?? (r['COUNT(*)'] as int? ?? 0);
    result[uid] = cnt;
  }
  return result;
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
  try {
    await _ensureUserExists();
  } catch (e, st) {
    log('Warning: _ensureUserExists failed, continuing insert. $e\n$st');
  }
  final db = await _db();
  // Evitar duplicados: eliminar cualquier fila existente con el mismo id y uid_correo
  try {
    // Ejecutar delete + insert en una transacción para evitar race conditions
    final inserted = await db.transaction<int>((txn) async {
      try {
        await txn.delete('gastos', where: 'id = ? AND uid_correo = ?', whereArgs: [expense.id, uid]);
      } catch (_) {}
      final rowId = await txn.insert('gastos', {
        'uid_correo': uid,
        'nombre': expense.title,
        'fecha': expense.date.millisecondsSinceEpoch,
        'cantidad': expense.amount,
        'categoria': _categoryToString(expense.category),
        'subcategoria': expense.subcategoryId,
        'sync_status': expense.syncStatus.index,
        'id': expense.id,
      });
      return rowId;
    });
    log('Gasto insertado localmente: ${expense.id} (uid_correo: $uid) -> inserted rowId: $inserted');
    return;
  } catch (e, st) {
    log('Warning: transacción insert fallida, intentando insert simple: $e\n$st');
  }
  // Fallback: intento simple si la transacción falla
  final inserted = await db.insert('gastos', {
    'uid_correo': uid,
    'nombre': expense.title,
    'fecha': expense.date.millisecondsSinceEpoch,
    'cantidad': expense.amount,
    'categoria': _categoryToString(expense.category),
    'subcategoria': expense.subcategoryId,
    'sync_status': expense.syncStatus.index,
    'id': expense.id,
  });
  log('Gasto insertado localmente: ${expense.id} (uid_correo: $uid) -> inserted rowId: $inserted');
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
  log('Gasto actualizado localmente: ${expense.id} (uid_correo: $uid)');
}

Future<void> updateSyncStatusImpl(String expenseId, SyncStatus status) async {
  final uid = await getUserUid();
  if (uid == null) return;
  final db = await _db();
  final count = await db.update(
    'gastos',
    {'sync_status': status.index},
    where: 'id = ? AND uid_correo = ?',
    whereArgs: [expenseId, uid],
  );
  log('Sync status actualizado localmente: ${expenseId} -> ${status.toString()} (uid_correo: $uid). Rows affected: $count');
}

Future<void> deleteExpenseImpl(String expenseId, {bool localOnly = false}) async {
  final uid = await getUserUid();
  if (uid == null) return;
  final db = await _db();
  final count = await db.delete('gastos', where: 'id = ? AND uid_correo = ?', whereArgs: [expenseId, uid]);
  log('Gasto eliminado localmente: $expenseId (uid_correo: $uid). Rows deleted: $count');
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
  // Ejecutar reemplazo completo en una transacción para evitar estados intermedios
  await db.transaction((txn) async {
    await txn.delete('gastos', where: 'uid_correo = ?', whereArgs: [uid]);
    for (final expense in expenses) {
      await txn.insert('gastos', {
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
  });
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
