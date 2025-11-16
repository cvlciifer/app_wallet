import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/core/data_base_local/local_crud.dart';
import 'package:app_wallet/core/sync_service/sync_service.dart';
import 'package:app_wallet/core/data_remote/firebase_Service.dart';
import 'package:app_wallet/core/models/profile/ingresos_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IngresosNotifier extends StateNotifier<IngresosState> {
  IngresosNotifier() : super(const IngresosState());

  Future<void> init() async {
    await loadLocalIncomes();
    // Ensure startOffset is within allowed sliding window relative to now
    setStartOffset(state.startOffset);
  }

  void setStartOffset(int offset) {
    // Clamp offset to [-12, +12] relative to current month so the UI only
    // allows selecting start months within one year back/forward.
    final clamped = offset < -12 ? -12 : (offset > 12 ? 12 : offset);
    if (clamped == state.startOffset) return;
    state = state.copyWith(startOffset: clamped);
    generatePreview();
  }

  Future<void> loadLocalIncomes() async {
    try {
      final rows = await getIncomesLocalImpl();
      final map = <String, Map<String, dynamic>>{};
      for (final r in rows) {
        final id = r['id']?.toString() ?? '';
        // Skip tombstones marked as pendingDelete so UI hides deleted incomes
        final syncStatus = r['sync_status'] as int? ?? 0;
        if (syncStatus == SyncStatus.pendingDelete.index) continue;
        if (id.isNotEmpty) map[id] = Map<String, dynamic>.from(r);
      }
      state = state.copyWith(localIncomes: map);
    } catch (_) {
      // ignore errors silently for now to preserve UX
    }
  }

  void setMonths(int m) {
    final int clamped = m < 1 ? 1 : (m > 12 ? 12 : m);
    if (clamped == state.months) return;
    state = state.copyWith(months: clamped);
    generatePreview();
  }

  void generatePreview() {
    // Generate preview months starting at `startOffset` for `months` entries.
    // `startOffset` may be negative (months before current), and `months` is in [1..12].
    final now = DateTime.now();
    final List<DateTime> list = [];
    final start = state.startOffset;
    final count = state.months <= 0 ? 1 : state.months;
    for (var i = 0; i < count; i++) {
      final offset = start + i;
      final d = DateTime(now.year, now.month + offset, 1);
      list.add(d);
    }
    state = state.copyWith(previewMonths: list);
  }

  /// Update or create a specific income row for a date (1st day of month).
  /// Updates both local DB and attempts remote upsert in background.
  Future<bool> updateIncomeForDate(DateTime date, int ingresoFijo, int? ingresoImprevisto) async {
    final id = '${date.year}${date.month.toString().padLeft(2, '0')}';
    try {
      // local-first
      await createIncomeLocalImpl(date, ingresoFijo, ingresoImprevisto, id: id, syncStatus: SyncStatus.pendingUpdate.index);
    } catch (_) {}

    // attempt remote upsert in background
    Future.microtask(() async {
      try {
        final ok = await upsertIncomeEntry(date, ingresoFijo, ingresoImprevisto, docId: id);
        if (ok) {
          await createIncomeLocalImpl(date, ingresoFijo, ingresoImprevisto, id: id, syncStatus: SyncStatus.synced.index);
        } else {
          await createIncomeLocalImpl(date, ingresoFijo, ingresoImprevisto, id: id, syncStatus: SyncStatus.pendingUpdate.index);
        }
      } catch (_) {
        try {
          await createIncomeLocalImpl(date, ingresoFijo, ingresoImprevisto, id: id, syncStatus: SyncStatus.pendingUpdate.index);
        } catch (_) {}
      }
    });

    // Refresh local cache
    await loadLocalIncomes();
    generatePreview();
    return true;
  }

  /// Delete an income for the provided date (1st day of month).
  /// Works both online and offline: if we have a user email we attempt
  /// an immediate remote delete, otherwise mark the local row as
  /// pendingDelete so the SyncService will remove it when online.
  Future<bool> deleteIncomeForDate(DateTime date) async {
    final id = '${date.year}${date.month.toString().padLeft(2, '0')}';
    try {
      // Always mark a tombstone locally so the UI can hide the income
      // immediately and SyncService can process the deletion later.
      await updateIncomeSyncStatusImpl(id, SyncStatus.pendingDelete);

      final current = Map<String, Map<String, dynamic>>.from(state.localIncomes);
      current.remove(id);
      state = state.copyWith(localIncomes: current);

      // Attempt remote delete in background if we have an authenticated email.
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email != null && email.isNotEmpty) {
        Future.microtask(() async {
          try {
            final docRef = FirebaseFirestore.instance
                .collection('usuarios')
                .doc(email)
                .collection('ingresos')
                .doc(id);
            await docRef.delete();
            // remote delete succeeded: remove local tombstone
            try {
              await deleteIncomeLocal(id);
            } catch (_) {}
          } catch (_) {
            // leave tombstone for SyncService to retry
          }
        });
      }

      return true;
    } catch (e, st) {
      // Ensure we at least returned true to indicate the UI was updated.
      log('deleteIncomeForDate error: $e\n$st');
      return true;
    }
  }

  Future<bool> save(int amount) async {
    final m = state.months;
    if (amount <= 0 || m <= 0) return false;
    state = state.copyWith(isSaving: true);
    try {
      final now = DateTime.now();
      // Local-first: persist all income entries locally with pendingCreate
      // status so the UI and reports work offline immediately. Then attempt
      // to push to Firestore in background; if successful, update the local
      // sync_status to synced.
      final List<Map<String, dynamic>> localRows = [];
      for (var i = 0; i < m; i++) {
        final date = DateTime(now.year, now.month + i, 1);
        final id = '${date.year}${date.month.toString().padLeft(2, '0')}';
        try {
          await createIncomeLocalImpl(date, amount, null,
              id: id, syncStatus: SyncStatus.pendingCreate.index);
        } catch (_) {
          // best-effort: if writing local fails, continue
        }
        localRows.add({'date': date, 'id': id});
      }

      // Background sync: try to push each entry to Firestore and update local status
      Future.microtask(() async {
        for (final row in localRows) {
          final DateTime date = row['date'] as DateTime;
          final id = row['id'] as String;
          try {
            final ok = await upsertIncomeEntry(date, amount, null, docId: id);
            if (ok) {
              await createIncomeLocalImpl(date, amount, null, id: id, syncStatus: SyncStatus.synced.index);
            } else {
              await createIncomeLocalImpl(date, amount, null, id: id, syncStatus: SyncStatus.pendingCreate.index);
            }
          } catch (_) {
            try {
              await createIncomeLocalImpl(date, amount, null, id: id, syncStatus: SyncStatus.pendingCreate.index);
            } catch (_) {}
          }
        }
      });
      await loadLocalIncomes();
      generatePreview();
      return true;
    } catch (_) {
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final ingresosProvider =
    StateNotifierProvider<IngresosNotifier, IngresosState>((ref) {
  final ctrl = IngresosNotifier();

  return ctrl;
});
