import 'dart:developer';
import '../sync_service/sync_service.dart';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/core/models/recurring_expense.dart';
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
  // Special helper used when performing a delete while offline: remove
  // recurrence mapping rows immediately so the UI/registry reflects the
  // deletion, but keep a tombstone gasto row with sync_status = pendingDelete
  // so the SyncService can remove the remote document later.
  Future<void> deleteExpenseOffline(String expenseId) => deleteExpenseOfflineImpl(expenseId);
  Future<List<Expense>> getPendingExpenses() => getPendingExpensesImpl();
  Future<void> replaceAllExpenses(List<Expense> expenses) => replaceAllExpensesImpl(expenses);
  Future<void> reconcileRemoteExpenses(List<Expense> remoteExpenses) => reconcileRemoteExpensesImpl(remoteExpenses);
  Future<void> reconstructRecurrencesFromExpenses(List<Expense> expenses) => reconstructRecurrencesFromExpensesImpl(expenses);
  Future<Map<String, int>> getGastosCountByUid() => getGastosCountByUidImpl();
  
  // Recurring expenses
  Future<void> insertRecurring(RecurringExpense recurring, List<Expense> generatedExpenses) => insertRecurringImpl(recurring, generatedExpenses);
  Future<List<RecurringExpense>> getRecurrents() => getRecurrentsImpl();
  Future<List<Map<String, dynamic>>> getRecurringItems(String recurrenceId) => getRecurringItemsImpl(recurrenceId);
  Future<void> updateRecurringItemAmount(String recurrenceId, int monthIndex, double newAmount) => updateRecurringItemAmountImpl(recurrenceId, monthIndex, newAmount);
  Future<void> deleteRecurrenceFromMonth(String recurrenceId, int fromMonthIndex) => deleteRecurrenceFromMonthImpl(recurrenceId, fromMonthIndex);
  Future<void> deleteRecurrence(String recurrenceId) => deleteRecurrenceImpl(recurrenceId);
  
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

  // Perform deletion and also reconcile any recurrence mapping that referenced this expense.
  await db.transaction((txn) async {
    // Delete the expense row for this user
    try {
      await txn.delete('gastos', where: 'id = ? AND uid_correo = ?', whereArgs: [expenseId, uid]);
      log('Gasto eliminado localmente: $expenseId (uid_correo: $uid)');
    } catch (e, st) {
      log('deleteExpenseImpl: error eliminando gasto $expenseId -> $e\n$st');
    }

    // If this expense was part of a recurrence, remove the mapping and update metadata
    try {
      final maps = await txn.query('gastos_recurrentes_items', where: 'expense_id = ?', whereArgs: [expenseId]);
      for (final m in maps) {
        final recurrenceId = m['recurrence_id'] as String?;
        final uidItem = m['uid_item'];
        // remove mapping row
        if (uidItem != null) {
          await txn.delete('gastos_recurrentes_items', where: 'uid_item = ?', whereArgs: [uidItem]);
        }

        if (recurrenceId != null) {
          // Count remaining mapping items for this recurrence
          final remaining = await txn.query('gastos_recurrentes_items', where: 'recurrence_id = ?', whereArgs: [recurrenceId]);
          if (remaining.isEmpty) {
            // No months left — remove recurrence metadata
            await txn.delete('gastos_recurrentes', where: 'id = ?', whereArgs: [recurrenceId]);
            log('Recurrence $recurrenceId removed because no months remain');
          } else {
            // Reindex month_index sequentially by fecha and update meses to remaining count
            remaining.sort((a, b) => (a['fecha'] as int).compareTo(b['fecha'] as int));
            for (var i = 0; i < remaining.length; i++) {
              final uidItemRem = remaining[i]['uid_item'];
              if (uidItemRem != null) {
                await txn.update('gastos_recurrentes_items', {'month_index': i}, where: 'uid_item = ?', whereArgs: [uidItemRem]);
              }
            }
            await txn.update('gastos_recurrentes', {'meses': remaining.length}, where: 'id = ?', whereArgs: [recurrenceId]);
            log('Recurrence $recurrenceId updated meses=${remaining.length} after deleting expense $expenseId');
          }
        }
      }
    } catch (e, st) {
      log('deleteExpenseImpl: error reconciliando mappings para $expenseId -> $e\n$st');
    }
  });
}

Future<void> deleteExpenseOfflineImpl(String expenseId) async {
  final uid = await getUserUid();
  if (uid == null) return;
  final db = await _db();

  // Fetch the existing gasto row if present so we can reinsert a tombstone
  // preserving basic fields (helps keep logs/diagnostics meaningful).
  final existing = await db.query('gastos', where: 'id = ? AND uid_correo = ?', whereArgs: [expenseId, uid], limit: 1);
  Map<String, dynamic>? saved;
  if (existing.isNotEmpty) {
    saved = Map<String, dynamic>.from(existing.first);
  }

  await db.transaction((txn) async {
    // Remove recurrence mapping items and update metadata similar to deleteExpenseImpl
    try {
      final maps = await txn.query('gastos_recurrentes_items', where: 'expense_id = ?', whereArgs: [expenseId]);
      for (final m in maps) {
        final recurrenceId = m['recurrence_id'] as String?;
        final uidItem = m['uid_item'];
        if (uidItem != null) {
          await txn.delete('gastos_recurrentes_items', where: 'uid_item = ?', whereArgs: [uidItem]);
        }

        if (recurrenceId != null) {
          final remaining = await txn.query('gastos_recurrentes_items', where: 'recurrence_id = ?', whereArgs: [recurrenceId]);
          if (remaining.isEmpty) {
            await txn.delete('gastos_recurrentes', where: 'id = ?', whereArgs: [recurrenceId]);
          } else {
            remaining.sort((a, b) => (a['fecha'] as int).compareTo(b['fecha'] as int));
            for (var i = 0; i < remaining.length; i++) {
              final uidItemRem = remaining[i]['uid_item'];
              if (uidItemRem != null) {
                await txn.update('gastos_recurrentes_items', {'month_index': i}, where: 'uid_item = ?', whereArgs: [uidItemRem]);
              }
            }
            await txn.update('gastos_recurrentes', {'meses': remaining.length}, where: 'id = ?', whereArgs: [recurrenceId]);
          }
        }
      }
    } catch (e, st) {
      log('deleteExpenseOfflineImpl: error reconciliando mappings para $expenseId -> $e\n$st');
    }

    // Delete the visible gasto row so UI reflects deletion immediately
    try {
      await txn.delete('gastos', where: 'id = ? AND uid_correo = ?', whereArgs: [expenseId, uid]);
    } catch (e, st) {
      log('deleteExpenseOfflineImpl: error eliminando gasto $expenseId -> $e\n$st');
    }

    // Insert a tombstone row so the sync process can detect and remove the remote doc later.
    // Use preserved fields when available to make tombstone more informative.
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await txn.insert('gastos', {
        'uid_correo': uid,
        'nombre': saved?['nombre'] ?? '__deleted__',
        'fecha': saved?['fecha'] ?? now,
        'cantidad': saved?['cantidad'] ?? 0,
        'categoria': saved?['categoria'] ?? 'tombstone',
        'subcategoria': saved?['subcategoria'],
        'sync_status': SyncStatus.pendingDelete.index,
        'id': expenseId,
      });
    } catch (e, st) {
      log('deleteExpenseOfflineImpl: error insertando tombstone para $expenseId -> $e\n$st');
    }
  });
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

/// Merge remote expenses into local DB but preserve local pending changes.
///
/// Rules:
/// - For each remote expense: insert or update local row with sync_status = synced.
/// - For local rows that are synced but not present in remote list: delete them (they were removed remotely).
/// - Local rows that are pendingCreate/pendingUpdate/pendingDelete are preserved.
Future<void> reconcileRemoteExpensesImpl(List<Expense> remoteExpenses) async {
  final uid = await getUserUid();
  if (uid == null) return;
  final db = await _db();
  final remoteIds = remoteExpenses.map((e) => e.id).toSet();

  // Process remote expenses in batches to avoid blocking UI for long periods.
  const batchSize = 50;
  for (var i = 0; i < remoteExpenses.length; i += batchSize) {
    final batch = remoteExpenses.sublist(i, (i + batchSize).clamp(0, remoteExpenses.length));
    await db.transaction((txn) async {
      for (final expense in batch) {
        try {
          await txn.delete('gastos', where: 'id = ? AND uid_correo = ?', whereArgs: [expense.id, uid]);
        } catch (_) {}
        await txn.insert('gastos', {
          'uid_correo': uid,
          'nombre': expense.title,
          'fecha': expense.date.millisecondsSinceEpoch,
          'cantidad': expense.amount,
          'categoria': _categoryToString(expense.category),
          'subcategoria': expense.subcategoryId,
          'sync_status': SyncStatus.synced.index,
          'id': expense.id,
        });
      }
    });
    // yield to event loop so UI can respond
    await Future.delayed(const Duration(milliseconds: 40));
  }

  // Delete local rows that are synced but not present remotely. Do in batches.
  final localRows = await db.query('gastos', where: 'uid_correo = ?', whereArgs: [uid]);
  final toDelete = <String>[];
  for (final r in localRows) {
    final localId = r['id'] as String?;
    final localSync = r['sync_status'] as int? ?? SyncStatus.synced.index;
    if (localId == null) continue;
    if (!remoteIds.contains(localId) && localSync == SyncStatus.synced.index) {
      toDelete.add(localId);
    }
  }
  for (var i = 0; i < toDelete.length; i += batchSize) {
    final batch = toDelete.sublist(i, (i + batchSize).clamp(0, toDelete.length));
    await db.transaction((txn) async {
      for (final id in batch) {
        await txn.delete('gastos', where: 'id = ? AND uid_correo = ?', whereArgs: [id, uid]);
      }
    });
    await Future.delayed(const Duration(milliseconds: 40));
  }
}

/// Reconstruct recurrence metadata from existing expenses when metadata is missing.
///
/// Looks for expense IDs that follow the pattern '<recurrenceId>-<index>' and
/// creates `gastos_recurrentes` and `gastos_recurrentes_items` rows if they
/// aren't already present. This helps recover recurrents after a reinstall
/// where the local metadata was lost but individual expenses remain in Firestore.
Future<void> reconstructRecurrencesFromExpensesImpl(List<Expense> expenses) async {
  final db = await _db();
  // Group expenses by presumed recurrence prefix (uuid part before last '-')
  final Map<String, List<Expense>> groups = {};
  final idRegex = RegExp(r'^(.+)-(\d+)\$');
  for (final e in expenses) {
    final m = idRegex.firstMatch(e.id);
    if (m == null) continue;
    final prefix = m.group(1)!;
    groups.putIfAbsent(prefix, () => []).add(e);
  }

  if (groups.isEmpty) return;

  await db.transaction((txn) async {
    for (final entry in groups.entries) {
      final prefix = entry.key;
      final items = entry.value;
      // If recurrence metadata already exists, skip
      final exists = await txn.query('gastos_recurrentes', where: 'id = ?', whereArgs: [prefix]);
      if (exists.isNotEmpty) continue;

      // Sort items by date ascending and create metadata from first item
      items.sort((a, b) => a.date.compareTo(b.date));
      final first = items.first;
      final startYear = first.date.year;
      final startMonth = first.date.month;
      final dayOfMonth = first.date.day;
      final meses = items.length;

      await txn.insert('gastos_recurrentes', {
        'id': prefix,
        'uid_correo': first.syncStatus == SyncStatus.synced ? (await getUserUid()) : (await getUserUid()),
        'nombre': first.title,
        'cantidad': first.amount.toInt(),
        'categoria': _categoryToString(first.category),
        'subcategoria': first.subcategoryId,
        'dia': dayOfMonth,
        'meses': meses,
        'start_year': startYear,
        'start_month': startMonth,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': SyncStatus.synced.index,
      });

      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        await txn.insert('gastos_recurrentes_items', {
          'recurrence_id': prefix,
          'expense_id': it.id,
          'fecha': it.date.millisecondsSinceEpoch,
          'cantidad': it.amount.toInt(),
          'month_index': i,
          'mutable': 0,
          'sync_status': SyncStatus.synced.index,
        });
      }
    }
  });
}

Future<void> reconstructRecurrencesFromExpenses(List<Expense> expenses) => reconstructRecurrencesFromExpensesImpl(expenses);

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

/// Recurring implementation helpers
Future<void> insertRecurringImpl(RecurringExpense recurring, List<Expense> generatedExpenses) async {
  final uid = await getUserUid();
  if (uid == null) return;
  final db = await _db();
  final createdAt = DateTime.now().millisecondsSinceEpoch;
  final recurrenceId = recurring.id;

  await db.transaction((txn) async {
    // Insert into gastos_recurrentes
    await txn.insert('gastos_recurrentes', {
      'id': recurrenceId,
      'uid_correo': uid,
      'nombre': recurring.title,
      'cantidad': recurring.amount.toInt(),
      'categoria': recurring.category.toString().split('.').last,
      'subcategoria': recurring.subcategoryId,
      'dia': recurring.dayOfMonth,
      'meses': recurring.months,
      'start_year': recurring.startYear,
      'start_month': recurring.startMonth,
      'created_at': createdAt,
      'sync_status': SyncStatus.pendingCreate.index,
    });

    // Insert generated expenses and mapping items
    for (var i = 0; i < generatedExpenses.length; i++) {
      final e = generatedExpenses[i];
      // insert expense
      try {
        await txn.delete('gastos', where: 'id = ? AND uid_correo = ?', whereArgs: [e.id, uid]);
      } catch (_) {}
      await txn.insert('gastos', {
        'uid_correo': uid,
        'nombre': e.title,
        'fecha': e.date.millisecondsSinceEpoch,
        'cantidad': e.amount,
        'categoria': e.category.toString().split('.').last,
        'subcategoria': e.subcategoryId,
        'sync_status': e.syncStatus.index,
        'id': e.id,
      });

      // map item
      await txn.insert('gastos_recurrentes_items', {
        'recurrence_id': recurrenceId,
        'expense_id': e.id,
        'fecha': e.date.millisecondsSinceEpoch,
        'cantidad': e.amount.toInt(),
        'month_index': i,
        'mutable': 0,
        'sync_status': SyncStatus.pendingCreate.index,
      });
    }
  });
}

Future<List<RecurringExpense>> getRecurrentsImpl() async {
  final uid = await getUserUid();
  if (uid == null) return [];
  final db = await _db();
  final rows = await db.query('gastos_recurrentes', where: 'uid_correo = ?', whereArgs: [uid], orderBy: 'created_at DESC');
  return rows.map((r) {
    return RecurringExpense(
      id: r['id'] as String,
      title: r['nombre'] as String? ?? '',
      amount: (r['cantidad'] as num).toDouble(),
      dayOfMonth: r['dia'] as int,
      months: r['meses'] as int,
      startYear: r['start_year'] as int,
      startMonth: r['start_month'] as int,
      category: _mapCategory(r['categoria'] as String? ?? ''),
      subcategoryId: r['subcategoria'] as String?,
    );
  }).toList();
}

Future<List<Map<String, dynamic>>> getRecurringItemsImpl(String recurrenceId) async {
  final db = await _db();
  final rows = await db.query('gastos_recurrentes_items', where: 'recurrence_id = ?', whereArgs: [recurrenceId], orderBy: 'month_index ASC');
  return rows;
}

Future<void> updateRecurringItemAmountImpl(String recurrenceId, int monthIndex, double newAmount) async {
  final db = await _db();
  // Update all items from the selected month (inclusive) until the end of recurrence
  // Find the selected item's fecha and use it as cutoff so previous months are untouched.
  final selectedRows = await db.query('gastos_recurrentes_items', where: 'recurrence_id = ? AND month_index = ?', whereArgs: [recurrenceId, monthIndex], limit: 1);
  if (selectedRows.isEmpty) return;
  final cutoffFecha = selectedRows.first['fecha'] as int;

  final rows = await db.query('gastos_recurrentes_items', where: 'recurrence_id = ? AND fecha >= ?', whereArgs: [recurrenceId, cutoffFecha]);
  if (rows.isEmpty) return;
  await db.transaction((txn) async {
    for (final r in rows) {
      await txn.update('gastos_recurrentes_items', {
        'cantidad': newAmount.toInt(),
        'mutable': 1,
        'sync_status': SyncStatus.pendingUpdate.index,
      }, where: 'uid_item = ?', whereArgs: [r['uid_item']]);

      final expenseId = r['expense_id'] as String;
      // update the associated expense row too
      await txn.update('gastos', {'cantidad': newAmount, 'sync_status': SyncStatus.pendingUpdate.index}, where: 'id = ?', whereArgs: [expenseId]);
    }
  });
}

Future<void> deleteRecurrenceFromMonthImpl(String recurrenceId, int fromMonthIndex) async {
  final db = await _db();
  // Find the fecha of the selected month_index (cutoff). If not found, do nothing.
  final selectedRows = await db.query('gastos_recurrentes_items', where: 'recurrence_id = ? AND month_index = ?', whereArgs: [recurrenceId, fromMonthIndex], limit: 1);
  if (selectedRows.isEmpty) return;
  final cutoffFecha = selectedRows.first['fecha'] as int;

  // delete all items whose fecha >= cutoffFecha (i.e. from the selected month onward)
  final rows = await db.query('gastos_recurrentes_items', where: 'recurrence_id = ? AND fecha >= ?', whereArgs: [recurrenceId, cutoffFecha]);
  if (rows.isEmpty) return;
  await db.transaction((txn) async {
    for (final r in rows) {
      final expenseId = r['expense_id'] as String;
      // Mark the expense as pendingDelete so SyncService can delete it remotely.
      try {
        await txn.update('gastos', {'sync_status': SyncStatus.pendingDelete.index}, where: 'id = ?', whereArgs: [expenseId]);
      } catch (_) {
        // Fallback: if update fails, delete local row
        await txn.delete('gastos', where: 'id = ?', whereArgs: [expenseId]);
      }
      // remove the mapping row locally
      await txn.delete('gastos_recurrentes_items', where: 'uid_item = ?', whereArgs: [r['uid_item']]);
    }
    // Recompute remaining items and reindex month_index; delete metadata if none left
    final remaining = await txn.query('gastos_recurrentes_items', where: 'recurrence_id = ?', whereArgs: [recurrenceId]);
    if (remaining.isEmpty) {
      await txn.delete('gastos_recurrentes', where: 'id = ?', whereArgs: [recurrenceId]);
    } else {
      // Reindex month_index sequentially by fecha
      remaining.sort((a, b) => (a['fecha'] as int).compareTo(b['fecha'] as int));
      for (var i = 0; i < remaining.length; i++) {
        final uidItemRem = remaining[i]['uid_item'];
        if (uidItemRem != null) {
          await txn.update('gastos_recurrentes_items', {'month_index': i}, where: 'uid_item = ?', whereArgs: [uidItemRem]);
        }
      }
      await txn.update('gastos_recurrentes', {'meses': remaining.length}, where: 'id = ?', whereArgs: [recurrenceId]);
    }
  });
}

Future<void> deleteRecurrenceImpl(String recurrenceId) async {
  final db = await _db();
  await db.transaction((txn) async {
    final rows = await txn.query('gastos_recurrentes_items', where: 'recurrence_id = ?', whereArgs: [recurrenceId]);
    for (final r in rows) {
      final expenseId = r['expense_id'] as String;
      try {
        await txn.update('gastos', {'sync_status': SyncStatus.pendingDelete.index}, where: 'id = ?', whereArgs: [expenseId]);
      } catch (_) {
        await txn.delete('gastos', where: 'id = ?', whereArgs: [expenseId]);
      }
    }
    // remove mapping rows
    await txn.delete('gastos_recurrentes_items', where: 'recurrence_id = ?', whereArgs: [recurrenceId]);
    // remove metadata row
    await txn.delete('gastos_recurrentes', where: 'id = ?', whereArgs: [recurrenceId]);
  });
}
