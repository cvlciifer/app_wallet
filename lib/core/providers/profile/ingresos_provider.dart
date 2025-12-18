import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/core/data_base_local/local_crud.dart';
import 'package:app_wallet/core/sync_service/sync_service.dart';
import 'package:app_wallet/core/data_remote/firebase_Service.dart'
    as remoteService;
import 'package:app_wallet/core/models/profile/ingresos_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IngresosNotifier extends StateNotifier<IngresosState> {
  IngresosNotifier() : super(const IngresosState());

  Future<void> init() async {
    await loadLocalIncomes();
    setStartOffset(state.startOffset);
  }

  void setStartOffset(int offset) {
    final clamped = offset < -12 ? -12 : (offset > 12 ? 12 : offset);
    if (clamped == state.startOffset) return;
    state = state.copyWith(startOffset: clamped);
    generatePreview();
  }

  Future<void> loadLocalIncomes() async {
    try {
      final rows = await getIncomesLocalImpl();
      final currentUid = await getUserUid();
      log('loadLocalIncomes: resolved uid=$currentUid, localRows=${rows.length}');
      final map = <String, Map<String, dynamic>>{};
      final pendingDeleteIds = <String>{};
      for (final r in rows) {
        final id = r['id']?.toString() ?? '';
        final syncStatus = r['sync_status'] as int? ?? 0;
        if (syncStatus == SyncStatus.pendingDelete.index) {
          if (id.isNotEmpty) pendingDeleteIds.add(id);
          continue;
        }
        if (id.isNotEmpty) map[id] = Map<String, dynamic>.from(r);
      }

      // Try to fetch remote incomes and merge them into local DB, but do
      // NOT overwrite local rows that have pending changes.
      try {
        final remote = await remoteService.getAllIncomesFromFirestore();
        log('loadLocalIncomes: fetched remote incomes=${remote.length}');
        final remoteIds = <String>[];
        for (final inc in remote) {
          final id = inc['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          remoteIds.add(id);
        }
        final missing = remoteIds.where((id) => !map.containsKey(id)).toList();
        if (missing.isNotEmpty)
          log('loadLocalIncomes: remote ids missing locally: ${missing.join(', ')}');

        for (final inc in remote) {
          try {
            final id = inc['id']?.toString() ?? '';
            if (id.isEmpty) continue;
            final remoteFecha = inc['fecha'];
            DateTime fechaDt;
            if (remoteFecha is Timestamp) {
              fechaDt = remoteFecha.toDate();
            } else if (remoteFecha is int) {
              fechaDt = DateTime.fromMillisecondsSinceEpoch(remoteFecha);
            } else if (remoteFecha is String) {
              fechaDt = DateTime.tryParse(remoteFecha) ?? DateTime.now();
            } else {
              fechaDt = DateTime.now();
            }

            final fechaUtc = fechaDt.toUtc();
            final derivedId =
                '${fechaUtc.year}${fechaUtc.month.toString().padLeft(2, '0')}';

            if (pendingDeleteIds.contains(derivedId)) {
              log('loadLocalIncomes: skipping remote doc id=$id because derivedId=$derivedId is pendingDelete locally');
              continue;
            }
            if (pendingDeleteIds.contains(id)) {
              log('loadLocalIncomes: skipping remote doc id=$id because it is pendingDelete locally');
              continue;
            }

            final fijo = (inc['ingreso_fijo'] as int?) ?? 0;
            final imp = (inc['ingreso_imprevisto'] as int?) ?? 0;

            final localRow = map[id];
            final localSync = localRow != null
                ? (localRow['sync_status'] as int? ?? 0)
                : SyncStatus.synced.index;
            if (localRow != null && localSync != SyncStatus.synced.index) {
              continue;
            }

            log('loadLocalIncomes: inserting remote id=$id using uid=$currentUid');
            await createIncomeLocalImpl(fechaDt, fijo, imp,
                id: id, syncStatus: SyncStatus.synced.index);
            map[id] = {
              'id': id,
              'fecha': fechaDt.millisecondsSinceEpoch,
              'ingreso_fijo': fijo,
              'ingreso_imprevisto': imp,
              'ingreso_total': fijo + imp,
              'sync_status': SyncStatus.synced.index,
            };
          } catch (e, st) {
            log('loadLocalIncomes: error processing remote income id=${inc['id']}: $e\n$st');
          }
        }
      } catch (e, st) {
        log('loadLocalIncomes: failed fetching remote incomes: $e\n$st');
      }

      state = state.copyWith(localIncomes: map);
    } catch (e, st) {
      log('loadLocalIncomes error: $e\n$st');
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
        final ok = await remoteService
            .upsertIncomeEntry(date, ingresoFijo, ingresoImprevisto, docId: id);
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
            log('deleteIncomeForDate: requested remote delete for doc id=$id');

            try {
              final remoteList =
                  await remoteService.getAllIncomesFromFirestore();
              final targetYear = date.year;
              final targetMonth = date.month;
              for (final inc in remoteList) {
                try {
                  final rid = inc['id']?.toString() ?? '';
                  if (rid == id) continue;
                  final rf = inc['fecha'];
                  DateTime rdt;
                  if (rf is Timestamp) {
                    rdt = rf.toDate();
                  } else if (rf is int) {
                    rdt = DateTime.fromMillisecondsSinceEpoch(rf);
                  } else if (rf is String) {
                    rdt = DateTime.tryParse(rf) ?? DateTime.now();
                  } else {
                    rdt = DateTime.now();
                  }
                  if (rdt.year == targetYear && rdt.month == targetMonth) {
                    try {
                      final otherRef = FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(email)
                          .collection('ingresos')
                          .doc(rid);
                      await otherRef.delete();
                      log('deleteIncomeForDate: deleted remote doc with id=$rid matching fecha $rdt');
                    } catch (e, st) {
                      log('deleteIncomeForDate: failed deleting remote doc id=$rid -> $e\n$st');
                    }
                  }
                } catch (_) {}
              }
            } catch (e, st) {
              log('deleteIncomeForDate: error enumerating remote incomes -> $e\n$st');
            }

            try {
              final localRows = await getIncomesLocalImpl();
              final targetYear = date.year;
              final targetMonth = date.month;
              for (final lr in localRows) {
                try {
                  final lid = lr['id']?.toString() ?? '';
                  final lfecha = (lr['fecha'] as int?) ?? 0;
                  final ldt = DateTime.fromMillisecondsSinceEpoch(lfecha);
                  if (ldt.year == targetYear && ldt.month == targetMonth) {
                    try {
                      await deleteIncomeLocal(lid);
                      log('deleteIncomeForDate: deleted local income id=$lid matching month $targetYear-$targetMonth');
                    } catch (e, st) {
                      log('deleteIncomeForDate: failed deleting local id=$lid -> $e\n$st');
                    }
                  }
                } catch (_) {}
              }
            } catch (e, st) {
              log('deleteIncomeForDate: error enumerating local incomes -> $e\n$st');
            }
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
            final ok = await remoteService.upsertIncomeEntry(date, amount, null,
                docId: id);
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
