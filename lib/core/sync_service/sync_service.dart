import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home_section/presentation/new_expense/presentation/models/expense.dart';
import '../data_base_local/local_crud.dart';

enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete }

class SyncService {
  final LocalCrud localCrud;
  final FirebaseFirestore firestore;
  final String userEmail;
  bool _initializing = false;
  bool _syncingPending = false;

  SyncService({required this.localCrud, required this.firestore, required this.userEmail});

  Future<void> initializeLocalDbFromFirebase() async {
    if (_initializing) {
      log('initializeLocalDbFromFirebase: ya se está ejecutando, omitiendo llamada concurrente');
      return;
    }
    _initializing = true;
    final email = await _resolveEmail();
    if (email.isEmpty) {
      _initializing = false;
      log('initializeLocalDbFromFirebase: no hay email de usuario disponible');
      return;
    }
    log('Obteniendo gastos de Firestore para el usuario: $email');
    final expensesSnapshot = await firestore.collection('usuarios').doc(email).collection('gastos').get();
    log('Documentos encontrados en Firestore: ${expensesSnapshot.docs.length}');
    for (var doc in expensesSnapshot.docs) {
      log('DocID: \'${doc.id}\' Data: ${doc.data()}');
    }
    final expenses = expensesSnapshot.docs.map((doc) {
      final expense = Expense.fromFirestore(doc);
      log('Expense mapeado: id=${expense.id}, title=${expense.title}, amount=${expense.amount}, date=${expense.date}, category=${expense.category}');
      return expense;
    }).toList();
    try {
      // Use a safe reconcile to merge remote state into local DB while preserving any
      // local pending changes (creates/updates/deletes) so we don't accidentally
      // wipe unsynced user edits.
      await localCrud.reconcileRemoteExpenses(expenses);
      // Reconstruct recurrence metadata from expenses when needed (covers app re-installs)
      await localCrud.reconstructRecurrencesFromExpenses(expenses);
      log('Gastos reconciliados en la base local: ${expenses.length}');
      // Ahora sincronizar/descargar los ingresos también
      log('Obteniendo ingresos de Firestore para el usuario: $email');
      final incomesSnapshot = await firestore.collection('usuarios').doc(email).collection('ingresos').get();
      // Map docs defensively: ensure 'id' and 'fecha' are present and well-typed
      final incomes = incomesSnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        // Ensure id exists (use doc.id if backend didn't include it)
        data['id'] = data['id'] ?? doc.id;
        return data;
      }).toList();
      await localCrud.replaceAllIncomes(incomes);
      log('Ingresos guardados en la base local: ${incomes.length}');
    } finally {
      _initializing = false;
    }
  }

  Future<String> _resolveEmail() async {
    if (userEmail.isNotEmpty) return userEmail;
    final e = FirebaseAuth.instance.currentUser?.email;
    if (e != null && e.isNotEmpty) return e;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('userEmail');
      if (savedEmail != null && savedEmail.isNotEmpty) return savedEmail;
      // Do not fallback to UID here — Firestore collection uses email as document id.
      log('No saved userEmail found in prefs', name: 'SyncService');
    } catch (_) {}
    return '';
  }

  Future<void> syncPendingChanges() async {
    if (_syncingPending) {
      log('syncPendingChanges: ya en progreso, omitiendo llamada concurrente');
      return;
    }
    _syncingPending = true;
    log('syncPendingChanges: inicio');
    try {
  final pendingExpenses = await localCrud.getPendingExpenses();
  // Do not return early if there are no pending expenses: we still need to
  // process pending incomes. Returning early here left `_syncingPending` as
  // true and prevented future sync attempts. Instead, continue and handle
  // empty lists gracefully.

    // Process creates first, then updates, then deletes. This avoids cases where a
    // record is created and immediately deleted while still pending.
    final creates = pendingExpenses.where((e) => e.syncStatus == SyncStatus.pendingCreate).toList();
    final updates = pendingExpenses.where((e) => e.syncStatus == SyncStatus.pendingUpdate).toList();
    final deletes = pendingExpenses.where((e) => e.syncStatus == SyncStatus.pendingDelete).toList();

    // Helper to be resilient to individual failures.
    Future<void> _safeRun(Future<void> Function() fn) async {
      try {
        await fn();
      } catch (e, st) {
        log('syncPendingChanges item failed: $e\n$st', name: 'SyncService');
      }
    }

    // Creates
    for (final expense in creates) {
      await _safeRun(() async {
        final email = await _resolveEmail();
        if (email.isEmpty) throw Exception('No user email to sync create');
        final docRef = firestore.collection('usuarios').doc(email).collection('gastos').doc(expense.id);
        await docRef.set(expense.toFirestore());
        await localCrud.updateSyncStatus(expense.id, SyncStatus.synced);
        log('Synced pending create: ${expense.id}');
      });
    }

    // Updates
    for (final expense in updates) {
      await _safeRun(() async {
        final email = await _resolveEmail();
        if (email.isEmpty) throw Exception('No user email to sync update');
        final docRef = firestore.collection('usuarios').doc(email).collection('gastos').doc(expense.id);
        // If the document doesn't exist on server, set it instead of update
        final snapshot = await docRef.get();
        if (!snapshot.exists) {
          await docRef.set(expense.toFirestore());
        } else {
          await docRef.update(expense.toFirestore());
        }
        await localCrud.updateSyncStatus(expense.id, SyncStatus.synced);
        log('Synced pending update: ${expense.id}');
      });
    }

    // Deletes
    for (final expense in deletes) {
      await _safeRun(() async {
        final email = await _resolveEmail();
        if (email.isEmpty) throw Exception('No user email to sync delete');
        final docRef = firestore.collection('usuarios').doc(email).collection('gastos').doc(expense.id);
        try {
          await docRef.delete();
        } catch (_) {
          // ignore if remote delete fails (may not exist)
        }
        // Ensure local deletion of the record
        await localCrud.deleteExpense(expense.id, localOnly: true);
        log('Synced pending delete: ${expense.id}');
      });
    }
  // Incomes: sync pending incomes similarly to gastos
  try {
      final pendingIncomes = await localCrud.getPendingIncomes();
      if (pendingIncomes.isNotEmpty) {
        final creates = pendingIncomes.where((r) => (r['sync_status'] as int) == SyncStatus.pendingCreate.index).toList();
        final updates = pendingIncomes.where((r) => (r['sync_status'] as int) == SyncStatus.pendingUpdate.index).toList();
        final deletesIn = pendingIncomes.where((r) => (r['sync_status'] as int) == SyncStatus.pendingDelete.index).toList();

        for (final row in creates) {
          await _safeRun(() async {
            final email = await _resolveEmail();
            if (email.isEmpty) throw Exception('No user email to sync create');
            final docRef = firestore.collection('usuarios').doc(email).collection('ingresos').doc(row['id'] as String);
            await docRef.set({
              'fecha': Timestamp.fromMillisecondsSinceEpoch(row['fecha'] as int),
              'ingreso_fijo': row['ingreso_fijo'] ?? 0,
              'ingreso_imprevisto': row['ingreso_imprevisto'] ?? 0,
              'ingreso_total': row['ingreso_total'] ?? ((row['ingreso_fijo'] ?? 0) + (row['ingreso_imprevisto'] ?? 0)),
              'id': row['id'],
            });
            await localCrud.updateIncomeSyncStatus(row['id'] as String, SyncStatus.synced);
            log('Synced pending income create: ${row['id']}');
          });
        }

        for (final row in updates) {
          await _safeRun(() async {
            final email = await _resolveEmail();
            if (email.isEmpty) throw Exception('No user email to sync update');
            final docRef = firestore.collection('usuarios').doc(email).collection('ingresos').doc(row['id'] as String);
            final snapshot = await docRef.get();
            final payload = {
              'fecha': Timestamp.fromMillisecondsSinceEpoch(row['fecha'] as int),
              'ingreso_fijo': row['ingreso_fijo'] ?? 0,
              'ingreso_imprevisto': row['ingreso_imprevisto'] ?? 0,
              'ingreso_total': row['ingreso_total'] ?? ((row['ingreso_fijo'] ?? 0) + (row['ingreso_imprevisto'] ?? 0)),
              'id': row['id'],
            };
            if (!snapshot.exists) {
              await docRef.set(payload);
            } else {
              await docRef.update(payload);
            }
            await localCrud.updateIncomeSyncStatus(row['id'] as String, SyncStatus.synced);
            log('Synced pending income update: ${row['id']}');
          });
        }

        for (final row in deletesIn) {
          await _safeRun(() async {
            final email = await _resolveEmail();
            if (email.isEmpty) throw Exception('No user email to sync delete');
            final docRef = firestore.collection('usuarios').doc(email).collection('ingresos').doc(row['id'] as String);
            try {
              await docRef.delete();
            } catch (_) {}
            await localCrud.deleteIncome(row['id'] as String);
            log('Synced pending income delete: ${row['id']}');
          });
        }
      }
    } catch (e, st) {
      log('Error syncing pending incomes: $e\n$st');
    }
    } finally {
      _syncingPending = false;
      log('syncPendingChanges: fin');
    }
  }

  /// Detecta conexión y sincroniza automáticamente
  void startAutoSync() {
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await syncPendingChanges();
      }
    });
  }

  /// Crea un gasto (maneja local y remoto según conexión)
  Future<void> createExpense(Expense expense, {required bool hasConnection}) async {
    // Fast local-first insert to keep the UI responsive.
    // Always insert locally first as pendingCreate; if we have connectivity,
    // try to push to Firestore in background and update the sync status later.
    await localCrud.insertExpense(expense.copyWith(syncStatus: SyncStatus.pendingCreate));

    if (hasConnection) {
      // Fire-and-forget remote create. Any failures will be retried by
      // syncPendingChanges(). We catch errors to avoid unhandled exceptions.
      Future.microtask(() async {
        try {
          final email = await _resolveEmail();
          if (email.isEmpty) return;
          final docRef = firestore.collection('usuarios').doc(email).collection('gastos').doc(expense.id);
          await docRef.set(expense.toFirestore());
          await localCrud.updateSyncStatus(expense.id, SyncStatus.synced);
        } catch (e, st) {
          log('createExpense: remote create failed, will remain pending: $e\n$st', name: 'SyncService');
        }
      });
    }
  }

  /// Actualiza un gasto
  Future<void> updateExpense(Expense expense, {required bool hasConnection}) async {
    if (hasConnection) {
      final email = await _resolveEmail();
      if (email.isNotEmpty) {
        final docRef = firestore.collection('usuarios').doc(email).collection('gastos').doc(expense.id);
        final snapshot = await docRef.get();
        if (!snapshot.exists) {
          await docRef.set(expense.toFirestore());
        } else {
          await docRef.update(expense.toFirestore());
        }
        await localCrud.updateExpense(expense.copyWith(syncStatus: SyncStatus.synced));
        return;
      }
      await localCrud.updateExpense(expense.copyWith(syncStatus: SyncStatus.pendingUpdate));
    } else {
      await localCrud.updateExpense(expense.copyWith(syncStatus: SyncStatus.pendingUpdate));
    }
  }

  /// Borra un gasto
  Future<void> deleteExpense(String expenseId, {required bool hasConnection}) async {
    // Fast local-first deletion to keep UI responsive.
    // We always remove mappings and ensure there's a tombstone locally so
    // the remote deletion can be retried by the background sync if needed.
    final email = await _resolveEmail();
    if (hasConnection && email.isNotEmpty) {
      // Use the offline-delete helper which removes mappings and inserts a
      // tombstone (sync_status = pendingDelete) so UI updates immediately.
      await localCrud.deleteExpenseOffline(expenseId);

      // Fire-and-forget remote delete: attempt to remove remote doc in background.
      // If it fails, syncPendingChanges() will retry since we left a tombstone.
      Future.microtask(() async {
        try {
          final docRef = firestore.collection('usuarios').doc(email).collection('gastos').doc(expenseId);
          try {
            await docRef.delete();
          } catch (_) {
            // ignore individual delete failures; syncPendingChanges will retry
          }
          // After successful remote delete, ensure local tombstone is removed.
          try {
            await localCrud.deleteExpense(expenseId, localOnly: true);
          } catch (_) {}
        } catch (e, st) {
          log('deleteExpense background delete failed, will be retried by syncPendingChanges: $e\n$st', name: 'SyncService');
        }
      });
      return;
    }

    // Offline or no-email path: perform the offline deletion which inserts a
    // tombstone for later sync and updates mapping metadata immediately.
    await localCrud.deleteExpenseOffline(expenseId);
  }
}
