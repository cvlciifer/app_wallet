import 'dart:developer';
import '../sync_service/sync_service.dart';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

// Cache to avoid repeated expensive UID/email resolution during UI events.
// This reduces SharedPreferences/DB accesses that may cause visible pauses.
final Duration _uidCacheDuration = Duration(minutes: 5);
String? _cachedUserUid;
DateTime? _cachedUserUidAt;
String? _cachedUserEmail;
DateTime? _cachedUserEmailAt;

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
  
  // Incomes
  Future<void> createIncomeLocal(DateTime date, int ingresoFijo, int? ingresoImprevisto, {String? id, int syncStatus = 0}) =>
      createIncomeLocalImpl(date, ingresoFijo, ingresoImprevisto, id: id, syncStatus: syncStatus);
  Future<List<Map<String, dynamic>>> getIncomesLocal() => getIncomesLocalImpl();
  Future<List<Map<String, dynamic>>> getPendingIncomes() => getPendingIncomesImpl();
  Future<void> updateIncomeSyncStatus(String incomeId, SyncStatus status) => updateIncomeSyncStatusImpl(incomeId, status);
  Future<void> replaceAllIncomes(List<Map<String, dynamic>> incomes) => replaceAllIncomesImpl(incomes);
  Future<void> deleteIncome(String incomeId) => deleteIncomeLocal(incomeId);
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
  // Return cached uid if still fresh to avoid repeated SharedPreferences/DB work
  if (_cachedUserUid != null && _cachedUserUidAt != null && DateTime.now().difference(_cachedUserUidAt!) < _uidCacheDuration) {
    return _cachedUserUid;
  }

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null && uid.isNotEmpty) {
    _cachedUserUid = uid;
    _cachedUserUidAt = DateTime.now();
    return uid;
  }
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
        _cachedUserUid = resolved;
        _cachedUserUidAt = DateTime.now();
        return resolved;
      }
    }
    // Si aún no tenemos UID, buscar un UID fallback persistido localmente.
    final fallback = prefs.getString('localFallbackUid');
    if (fallback != null && fallback.isNotEmpty) {
      log('getUserUid: usando localFallbackUid -> $fallback');
      _cachedUserUid = fallback;
      _cachedUserUidAt = DateTime.now();
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
    _cachedUserUid = newLocalUid;
    _cachedUserUidAt = DateTime.now();
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
  // Return cached email if fresh
  if (_cachedUserEmail != null && _cachedUserEmailAt != null && DateTime.now().difference(_cachedUserEmailAt!) < _uidCacheDuration) {
    return _cachedUserEmail;
  }

  final email = FirebaseAuth.instance.currentUser?.email;
  if (email != null && email.isNotEmpty) {
    _cachedUserEmail = email;
    _cachedUserEmailAt = DateTime.now();
    return email;
  }
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('userEmail');
    if (saved != null && saved.isNotEmpty) {
      _cachedUserEmail = saved;
      _cachedUserEmailAt = DateTime.now();
      return saved;
    }
    return null;
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

/// Inserta o reemplaza una fila en la tabla `ingresos` para la fecha dada.
Future<void> createIncomeLocalImpl(DateTime date, int ingresoFijo, int? ingresoImprevisto, {String? id, int syncStatus = 0}) async {
  final uid = await getUserUid();
  if (uid == null) {
    log('createIncomeLocalImpl: no se encontró el usuario autenticado');
    return;
  }
  try {
    await _ensureUserExists();
  } catch (e, st) {
    log('Warning: _ensureUserExists failed for ingresos: $e\n$st');
  }

  final db = await _db();
  final fechaMs = date.millisecondsSinceEpoch;
  try {
    await db.transaction((txn) async {
      // Evitar duplicados para el mismo uid_correo y fecha (1er día del mes)
      // Intentar actualizar si existe
      final existing = await txn.query('ingresos', where: 'uid_correo = ? AND fecha = ?', whereArgs: [uid, fechaMs]);
      if (existing.isNotEmpty) {
        // Always ensure a stable id for the income row. Prefer provided id,
        // otherwise derive from date.
        final derivedId = id ?? '${date.year}${date.month.toString().padLeft(2, '0')}';
        final Map<String, Object?> updateMap = {'ingreso_fijo': ingresoFijo};
        if (ingresoImprevisto != null) updateMap['ingreso_imprevisto'] = ingresoImprevisto;
        final currentImprev = ingresoImprevisto ?? (existing.first['ingreso_imprevisto'] as int? ?? 0);
        updateMap['ingreso_total'] = ingresoFijo + currentImprev;
        updateMap['id'] = derivedId;
        updateMap['sync_status'] = syncStatus;
        await txn.update('ingresos', updateMap, where: 'uid_correo = ? AND fecha = ?', whereArgs: [uid, fechaMs]);
      } else {
        final total = ingresoFijo + (ingresoImprevisto ?? 0);
        final derivedId = id ?? '${date.year}${date.month.toString().padLeft(2, '0')}';
        await txn.insert('ingresos', {
          'id': derivedId,
          'uid_correo': uid,
          'fecha': fechaMs,
          'ingreso_fijo': ingresoFijo,
          'ingreso_imprevisto': ingresoImprevisto ?? 0,
          'ingreso_total': total,
          'sync_status': syncStatus,
        });
      }
    });
    log('Ingreso insertado localmente: fecha=$date, fijo=$ingresoFijo, imprevisto=$ingresoImprevisto (uid_correo: $uid)');
  } catch (e, st) {
    log('createIncomeLocalImpl: transacción fallida, intentando insert simple: $e\n$st');
    await db.insert('ingresos', {
      'id': id,
      'uid_correo': uid,
      'fecha': fechaMs,
      'ingreso_fijo': ingresoFijo,
      'ingreso_imprevisto': ingresoImprevisto ?? 0,
      'ingreso_total': ingresoFijo + (ingresoImprevisto ?? 0),
      'sync_status': syncStatus,
    });
  }
}

Future<List<Map<String, dynamic>>> getIncomesLocalImpl() async {
  final uid = await getUserUid();
  if (uid == null) {
    log('getIncomesLocalImpl: no se encontró el usuario autenticado');
    return [];
  }
  final db = await _db();
  final rows = await db.query('ingresos', where: 'uid_correo = ?', whereArgs: [uid], orderBy: 'fecha DESC');
  return rows;
}

Future<List<Map<String, dynamic>>> getPendingIncomesImpl() async {
  final uid = await getUserUid();
  if (uid == null) return [];
  final db = await _db();
  final rows = await db.query('ingresos', where: 'uid_correo = ? AND sync_status != ?', whereArgs: [uid, SyncStatus.synced.index]);
  return rows;
}

Future<void> updateIncomeSyncStatusImpl(String incomeId, SyncStatus status) async {
  final uid = await getUserUid();
  if (uid == null) return;
  final db = await _db();
  await db.update('ingresos', {'sync_status': status.index}, where: 'id = ? AND uid_correo = ?', whereArgs: [incomeId, uid]);
}

Future<void> replaceAllIncomesImpl(List<Map<String, dynamic>> incomes) async {
  final uid = await getUserUid();
  if (uid == null) return;
  final db = await _db();
  await db.transaction((txn) async {
    await txn.delete('ingresos', where: 'uid_correo = ?', whereArgs: [uid]);
    for (final income in incomes) {
      // Defensive parsing: fecha may be Timestamp, int, or missing. Ensure we store a valid int (msSinceEpoch).
      final rawFecha = income['fecha'];
      int fechaMs;
      if (rawFecha == null) {
        // If fecha is missing, fallback to now and log for diagnostics
        fechaMs = DateTime.now().millisecondsSinceEpoch;
        log('replaceAllIncomesImpl: income missing fecha, using now as fallback. income id=${income['id']}');
      } else if (rawFecha is Timestamp) {
        fechaMs = rawFecha.toDate().millisecondsSinceEpoch;
      } else if (rawFecha is int) {
        fechaMs = rawFecha;
      } else if (rawFecha is String) {
        fechaMs = int.tryParse(rawFecha) ?? DateTime.now().millisecondsSinceEpoch;
      } else {
        // unknown type
        fechaMs = DateTime.now().millisecondsSinceEpoch;
      }

      // Ensure we have an id for the income; if missing, derive one from year/month
      var idVal = income['id'];
      if (idVal == null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(fechaMs);
        idVal = '${dt.year}${dt.month.toString().padLeft(2, '0')}';
        log('replaceAllIncomesImpl: income missing id, derived id=$idVal from fecha');
      }

      await txn.insert('ingresos', {
        'id': idVal,
        'uid_correo': uid,
        'fecha': fechaMs,
        'ingreso_fijo': income['ingreso_fijo'] ?? 0,
        'ingreso_imprevisto': income['ingreso_imprevisto'] ?? 0,
        'ingreso_total': income['ingreso_total'] ?? ((income['ingreso_fijo'] ?? 0) + (income['ingreso_imprevisto'] ?? 0)),
        'sync_status': SyncStatus.synced.index,
      });
    }
  });
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

Future<void> deleteIncomeLocal(String incomeId) async {
  final uid = await getUserUid();
  if (uid == null) return;
  final db = await _db();
  await db.delete('ingresos', where: 'id = ? AND uid_correo = ?', whereArgs: [incomeId, uid]);
}
