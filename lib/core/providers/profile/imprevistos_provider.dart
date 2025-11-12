import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/core/data_base_local/local_crud.dart';
import 'package:app_wallet/core/sync_service/sync_service.dart';
import 'package:app_wallet/core/data_remote/firebase_Service.dart';
import 'package:app_wallet/core/providers/profile/ingresos_provider.dart';
import 'package:app_wallet/core/models/profile/imprevistos_state.dart';

class ImprevistosNotifier extends StateNotifier<ImprevistosState> {
  final Ref ref;

  ImprevistosNotifier(this.ref) : super(const ImprevistosState());

  void setShowMaxError(bool v) => state = state.copyWith(showMaxError: v);

  void setIsAmountValid(bool v) => state = state.copyWith(isAmountValid: v);

  void setSelectedMonthOffset(int offset) =>
      state = state.copyWith(selectedMonthOffset: offset);

  Future<bool> saveImprevisto(
      DateTime target, int initialFijo, int value) async {
    if (value <= 0) return false;
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true);
    try {
      final local = await getIncomesLocalImpl();
      final match = local.firstWhere(
        (r) => r['fecha'] == target.millisecondsSinceEpoch,
        orElse: () => {},
      );

      int fijo = initialFijo;
      if (match.isNotEmpty) fijo = (match['ingreso_fijo'] as int?) ?? fijo;

      final id = '${target.year}${target.month.toString().padLeft(2, '0')}';
      try {
        await upsertIncomeEntry(target, fijo, value, docId: id);
        await createIncomeLocalImpl(target, fijo, value,
            id: id, syncStatus: SyncStatus.synced.index);
      } catch (_) {
        await createIncomeLocalImpl(target, fijo, value,
            id: id, syncStatus: SyncStatus.pendingCreate.index);
      }

      try {
        await ref.read(ingresosProvider.notifier).loadLocalIncomes();
        ref.read(ingresosProvider.notifier).generatePreview();
      } catch (_) {}

      return true;
    } catch (e, st) {
      log('imprevistos_provider.saveImprevisto error: $e', stackTrace: st);
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final imprevistosProvider =
    StateNotifierProvider<ImprevistosNotifier, ImprevistosState>((ref) {
  return ImprevistosNotifier(ref);
});
