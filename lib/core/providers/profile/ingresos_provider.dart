import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/core/data_base_local/local_crud.dart';
import 'package:app_wallet/core/sync_service/sync_service.dart';
import 'package:app_wallet/core/data_remote/firebase_Service.dart';
import 'package:app_wallet/core/models/profile/ingresos_state.dart';

class IngresosNotifier extends StateNotifier<IngresosState> {
  IngresosNotifier() : super(const IngresosState());

  Future<void> init() async {
    await loadLocalIncomes();
    generatePreview();
  }

  Future<void> loadLocalIncomes() async {
    try {
      final rows = await getIncomesLocalImpl();
      final map = <String, Map<String, dynamic>>{};
      for (final r in rows) {
        final id = r['id']?.toString() ?? '';
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
    final now = DateTime.now();
    final List<DateTime> list = [];
    for (var i = 0; i < state.months; i++) {
      final d = DateTime(now.year, now.month + i, 1);
      list.add(d);
    }
    state = state.copyWith(previewMonths: list);
  }

  Future<bool> save(int amount) async {
    final m = state.months;
    if (amount <= 0 || m <= 0) return false;
    state = state.copyWith(isSaving: true);
    try {
      final now = DateTime.now();
      for (var i = 0; i < m; i++) {
        final date = DateTime(now.year, now.month + i, 1);
        final id = '${date.year}${date.month.toString().padLeft(2, '0')}';
        try {
          await upsertIncomeEntry(date, amount, null, docId: id);
          await createIncomeLocalImpl(date, amount, null,
              id: id, syncStatus: SyncStatus.synced.index);
        } catch (_) {
          try {
            await createIncomeLocalImpl(date, amount, null,
                id: id, syncStatus: SyncStatus.pendingCreate.index);
          } catch (_) {}
        }
      }
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
