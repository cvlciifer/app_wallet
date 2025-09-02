import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/expense.dart';
import '../service_db_local/local_crud.dart';

/// Estado de sincronización para los gastos
enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete }

class SyncService {
  final LocalCrud localCrud;
  final FirebaseFirestore firestore;
  final String userEmail;

  SyncService({required this.localCrud, required this.firestore, required this.userEmail});

  /// Inicializa la base local con los datos de Firebase
  Future<void> initializeLocalDbFromFirebase() async {
    print('Obteniendo gastos de Firestore para el usuario: $userEmail');
    final expensesSnapshot = await firestore.collection('usuarios').doc(userEmail).collection('gastos').get();
    print('Documentos encontrados en Firestore: ${expensesSnapshot.docs.length}');
    for (var doc in expensesSnapshot.docs) {
      print('DocID: \'${doc.id}\' Data: ${doc.data()}');
    }
    final expenses = expensesSnapshot.docs.map((doc) {
      final expense = Expense.fromFirestore(doc);
      print('Expense mapeado: id=${expense.id}, title=${expense.title}, amount=${expense.amount}, date=${expense.date}, category=${expense.category}');
      return expense;
    }).toList();
    await localCrud.replaceAllExpenses(expenses);
    print('Gastos guardados en la base local: ${expenses.length}');
  }

  /// Sincroniza los cambios pendientes de la base local a Firebase
  Future<void> syncPendingChanges() async {
    final pendingExpenses = await localCrud.getPendingExpenses();
    for (final expense in pendingExpenses) {
      switch (expense.syncStatus) {
        case SyncStatus.pendingCreate:
          final docRef = firestore.collection('usuarios').doc(userEmail).collection('gastos').doc(expense.id);
          await docRef.set(expense.toFirestore());
          await localCrud.updateSyncStatus(expense.id, SyncStatus.synced);
          break;
        case SyncStatus.pendingUpdate:
          final docRef = firestore.collection('usuarios').doc(userEmail).collection('gastos').doc(expense.id);
          await docRef.update(expense.toFirestore());
          await localCrud.updateSyncStatus(expense.id, SyncStatus.synced);
          break;
        case SyncStatus.pendingDelete:
          final docRef = firestore.collection('usuarios').doc(userEmail).collection('gastos').doc(expense.id);
          await docRef.delete();
          await localCrud.deleteExpense(expense.id, localOnly: true);
          break;
        case SyncStatus.synced:
          break;
      }
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
    if (hasConnection) {
  final docRef = firestore.collection('usuarios').doc(userEmail).collection('gastos').doc(expense.id);
      await docRef.set(expense.toFirestore());
      await localCrud.insertExpense(expense.copyWith(syncStatus: SyncStatus.synced));
    } else {
      await localCrud.insertExpense(expense.copyWith(syncStatus: SyncStatus.pendingCreate));
    }
  }

  /// Actualiza un gasto
  Future<void> updateExpense(Expense expense, {required bool hasConnection}) async {
    if (hasConnection) {
  final docRef = firestore.collection('usuarios').doc(userEmail).collection('gastos').doc(expense.id);
      await docRef.update(expense.toFirestore());
      await localCrud.updateExpense(expense.copyWith(syncStatus: SyncStatus.synced));
    } else {
      await localCrud.updateExpense(expense.copyWith(syncStatus: SyncStatus.pendingUpdate));
    }
  }

  /// Borra un gasto
  Future<void> deleteExpense(String expenseId, {required bool hasConnection}) async {
    if (hasConnection) {
  final docRef = firestore.collection('usuarios').doc(userEmail).collection('gastos').doc(expenseId);
      await docRef.delete();
      await localCrud.deleteExpense(expenseId);
    } else {
      await localCrud.updateSyncStatus(expenseId, SyncStatus.pendingDelete);
    }
  }
}
