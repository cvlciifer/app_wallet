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
      await localCrud.replaceAllExpenses(expenses);
      log('Gastos guardados en la base local: ${expenses.length}');
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
    final pendingExpenses = await localCrud.getPendingExpenses();
    if (pendingExpenses.isEmpty) return;

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
    _syncingPending = false;
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
    if (hasConnection) {
      final email = await _resolveEmail();
      if (email.isNotEmpty) {
        final docRef = firestore.collection('usuarios').doc(email).collection('gastos').doc(expense.id);
        await docRef.set(expense.toFirestore());
        await localCrud.insertExpense(expense.copyWith(syncStatus: SyncStatus.synced));
        return;
      }
      // if we don't have an email to sync to, fall back to pendingCreate so it will
      // be picked up when we can resolve the user email later
      await localCrud.insertExpense(expense.copyWith(syncStatus: SyncStatus.pendingCreate));
    } else {
      await localCrud.insertExpense(expense.copyWith(syncStatus: SyncStatus.pendingCreate));
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
    if (hasConnection) {
      final email = await _resolveEmail();
      if (email.isNotEmpty) {
        final docRef = firestore.collection('usuarios').doc(email).collection('gastos').doc(expenseId);
        try {
          await docRef.delete();
        } catch (_) {}
        await localCrud.deleteExpense(expenseId);
        return;
      }
      // If we can't resolve email, mark pending delete
      await localCrud.updateSyncStatus(expenseId, SyncStatus.pendingDelete);
    } else {
      await localCrud.updateSyncStatus(expenseId, SyncStatus.pendingDelete);
    }
  }
}
