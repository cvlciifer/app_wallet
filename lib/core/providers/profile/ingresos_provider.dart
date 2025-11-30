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
    final int clamped = m < 0 ? 0 : (m > 12 ? 12 : m);
    if (clamped == state.months) return;
    state = state.copyWith(months: clamped);
    generatePreview();
  }

  void generatePreview() {
    if (state.months <= 0) {
      state = state.copyWith(previewMonths: const []);
      return;
    }

    final now = DateTime.now();
    final List<DateTime> list = [];
    final start = state.startOffset;
    final count = state.months;
    for (var i = 0; i < count; i++) {
      final offset = start + i;
      final d = DateTime(now.year, now.month + offset, 1);
      list.add(d);
    }
    state = state.copyWith(previewMonths: list);
  }

  Future<bool> updateIncomeForDate(
      DateTime date, int ingresoFijo, int? ingresoImprevisto) async {
    final id = '${date.year}${date.month.toString().padLeft(2, '0')}';
    try {
      await createIncomeLocalImpl(date, ingresoFijo, ingresoImprevisto,
          id: id, syncStatus: SyncStatus.pendingUpdate.index);
    } catch (_) {}

    Future.microtask(() async {
      try {
        final ok = await upsertIncomeEntry(date, ingresoFijo, ingresoImprevisto,
            docId: id);
        if (ok) {
          await createIncomeLocalImpl(date, ingresoFijo, ingresoImprevisto,
              id: id, syncStatus: SyncStatus.synced.index);
        } else {
          await createIncomeLocalImpl(date, ingresoFijo, ingresoImprevisto,
              id: id, syncStatus: SyncStatus.pendingUpdate.index);
        }
      } catch (_) {
        try {
          await createIncomeLocalImpl(date, ingresoFijo, ingresoImprevisto,
              id: id, syncStatus: SyncStatus.pendingUpdate.index);
        } catch (_) {}
      }
    });

    // Refresh local cache
    await loadLocalIncomes();
    generatePreview();
    return true;
  }

  Future<bool> deleteIncomeForDate(DateTime date) async {
    final id = '${date.year}${date.month.toString().padLeft(2, '0')}';
    try {
      await updateIncomeSyncStatusImpl(id, SyncStatus.pendingDelete);

      final current =
          Map<String, Map<String, dynamic>>.from(state.localIncomes);
      current.remove(id);
      state = state.copyWith(localIncomes: current);

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
            try {
              await deleteIncomeLocal(id);
            } catch (_) {}
          } catch (_) {}
        });
      }

      return true;
    } catch (e, st) {
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
      final List<Map<String, dynamic>> localRows = [];
      for (var i = 0; i < m; i++) {
        final date = DateTime(now.year, now.month + i, 1);
        final id = '${date.year}${date.month.toString().padLeft(2, '0')}';
        try {
          await createIncomeLocalImpl(date, amount, null,
              id: id, syncStatus: SyncStatus.pendingCreate.index);
        } catch (_) {}
        localRows.add({'date': date, 'id': id});
      }

      Future.microtask(() async {
        for (final row in localRows) {
          final DateTime date = row['date'] as DateTime;
          final id = row['id'] as String;
          try {
            final ok = await upsertIncomeEntry(date, amount, null, docId: id);
            if (ok) {
              await createIncomeLocalImpl(date, amount, null,
                  id: id, syncStatus: SyncStatus.synced.index);
            } else {
              await createIncomeLocalImpl(date, amount, null,
                  id: id, syncStatus: SyncStatus.pendingCreate.index);
            }
          } catch (_) {
            try {
              await createIncomeLocalImpl(date, amount, null,
                  id: id, syncStatus: SyncStatus.pendingCreate.index);
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
