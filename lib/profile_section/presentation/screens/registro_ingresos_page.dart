import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/core/providers/profile/ingresos_provider.dart';
import 'package:app_wallet/core/sync_service/sync_service.dart';

class RegistroIngresosPage extends ConsumerStatefulWidget {
  const RegistroIngresosPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RegistroIngresosPage> createState() =>
      _RegistroIngresosPageState();
}

class _RegistroIngresosPageState extends ConsumerState<RegistroIngresosPage> {
  @override
  void initState() {
    super.initState();
    // Ensure we load local incomes and merge remote ones when opening the page.
    Future.microtask(
        () => ref.read(ingresosProvider.notifier).loadLocalIncomes());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ingresosProvider);
    final ctrl = ref.read(ingresosProvider.notifier);
    final formatter =
        NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    final entriesAll = state.localIncomes.values.toList();

    // Show all stored incomes from local DB (including past months).
    // Only skip tombstones (pendingDelete).
    final entries = entriesAll.where((row) {
      final syncStatus = row['sync_status'] as int? ?? 0;
      if (syncStatus == SyncStatus.pendingDelete.index) return false;
      return true;
    }).toList();

    // Deduplicate by year-month (in case the same month exists under
    // multiple db ids). Prefer rows with SyncStatus.synced, otherwise pick
    // the one with larger ingreso_total.
    final Map<int, Map<String, dynamic>> dedup = {};
    for (final row in entries) {
      final fechaMs = (row['fecha'] as int?) ?? 0;
      final dt = DateTime.fromMillisecondsSinceEpoch(fechaMs);
      final key = dt.year * 100 + dt.month;
      final existing = dedup[key];
      if (existing == null) {
        dedup[key] = row;
        continue;
      }
      final existSync =
          (existing['sync_status'] as int?) ?? SyncStatus.synced.index;
      final rowSync = (row['sync_status'] as int?) ?? SyncStatus.synced.index;
      if (existSync == SyncStatus.synced.index &&
          rowSync != SyncStatus.synced.index) {
        // keep existing
        continue;
      }
      if (rowSync == SyncStatus.synced.index &&
          existSync != SyncStatus.synced.index) {
        dedup[key] = row;
        continue;
      }
      final existTotal = (existing['ingreso_total'] as int?) ??
          ((existing['ingreso_fijo'] as int?) ?? 0) +
              ((existing['ingreso_imprevisto'] as int?) ?? 0);
      final rowTotal = (row['ingreso_total'] as int?) ??
          ((row['ingreso_fijo'] as int?) ?? 0) +
              ((row['ingreso_imprevisto'] as int?) ?? 0);
      if (rowTotal >= existTotal) dedup[key] = row;
    }

    final dedupedEntries = dedup.values.toList()
      ..sort((a, b) {
        final fa = (a['fecha'] as int?) ?? 0;
        final fb = (b['fecha'] as int?) ?? 0;
        return fa.compareTo(fb);
      });

    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold('Registro de ingresos', color: AwColors.white),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: TicketCard(
          notchDepth: 12,
          elevation: 6,
          color: AwColors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AwSpacing.s6,
                if (dedupedEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Image(
                            image: AWImage.ghost,
                            fit: BoxFit.contain,
                            width: 96,
                            height: 96,
                          ),
                        ),
                        AwSpacing.s6,
                        Center(
                          child: AwText.normal(
                            'No hay ingresos registrados aún.',
                            color: AwColors.modalGrey,
                            size: AwSize.s14,
                          ),
                        ),
                        AwSpacing.s6,
                      ],
                    ),
                  ),
                ...dedupedEntries.map((row) {
                  final fechaMs = (row['fecha'] as int?) ??
                      DateTime.now().millisecondsSinceEpoch;
                  final dt = DateTime.fromMillisecondsSinceEpoch(fechaMs);
                  final monthLabelRaw =
                      DateFormat('MMMM yyyy', 'es').format(dt);
                  final monthLabel = monthLabelRaw.isNotEmpty
                      ? '${monthLabelRaw[0].toUpperCase()}${monthLabelRaw.substring(1)}'
                      : monthLabelRaw;
                  final fijo = (row['ingreso_fijo'] as int?) ?? 0;
                  final imprevisto = (row['ingreso_imprevisto'] as int?) ?? 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: IncomePreviewTile(
                      monthLabel: monthLabel,
                      fijoText: formatter.format(fijo),
                      imprevistoText: formatter.format(imprevisto),
                      totalText: formatter.format(fijo + imprevisto),
                      onEdit: () async {
                        final fmt = NumberFormat.currency(
                            locale: 'es_CL', symbol: '', decimalDigits: 0);
                        final fijoCtrl =
                            TextEditingController(text: fmt.format(fijo));
                        final impCtrl =
                            TextEditingController(text: fmt.format(imprevisto));
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => Dialog(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const AwText.bold('Editar ingreso',
                                      size: AwSize.s16),
                                  AwSpacing.s,
                                  CustomTextField(
                                      controller: fijoCtrl,
                                      label: 'Ingreso mensual',
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        MaxAmountFormatter(
                                            maxDigits:
                                                MaxAmountFormatter.kEightDigits,
                                            maxAmount: MaxAmountFormatter
                                                .kEightDigitsMaxAmount),
                                        CLPTextInputFormatter()
                                      ]),
                                  AwSpacing.s6,
                                  CustomTextField(
                                      controller: impCtrl,
                                      label: 'Imprevisto (opcional)',
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        MaxAmountFormatter(
                                            maxDigits:
                                                MaxAmountFormatter.kEightDigits,
                                            maxAmount: MaxAmountFormatter
                                                .kEightDigitsMaxAmount),
                                        CLPTextInputFormatter()
                                      ]),
                                  AwSpacing.s12,
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('Cancelar')),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AwColors.lightBlue),
                                        child: const Text('Guardar'),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                        if (ok == true) {
                          final newFijo = int.tryParse(fijoCtrl.text
                                  .replaceAll(RegExp(r'[^0-9]'), '')) ??
                              0;
                          final newImp = int.tryParse(impCtrl.text
                                  .replaceAll(RegExp(r'[^0-9]'), '')) ??
                              0;
                          final date = DateTime(dt.year, dt.month, 1);

                          // Activate global loader while updating
                          ref.read(globalLoaderProvider.notifier).state = true;
                          try {
                            await ctrl.updateIncomeForDate(
                                date, newFijo, newImp);
                            await ctrl.loadLocalIncomes();
                          } finally {
                            ref.read(globalLoaderProvider.notifier).state =
                                false;
                          }

                          String title = 'Ingreso actualizado';
                          try {
                            final originalFijo =
                                (row['ingreso_fijo'] as int?) ?? 0;
                            final originalImp =
                                (row['ingreso_imprevisto'] as int?) ?? 0;
                            final fijoChanged = originalFijo != newFijo;
                            final impChanged = originalImp != newImp;
                            if (fijoChanged && !impChanged) {
                              title = 'Ingreso mensual actualizado';
                            } else if (!fijoChanged && impChanged) {
                              title = 'Imprevisto actualizado';
                            } else if (fijoChanged && impChanged) {
                              title =
                                  'Ingreso mensual e imprevisto actualizados';
                            }
                          } catch (_) {}

                          try {
                            final overlayCtx =
                                Navigator.of(context, rootNavigator: true)
                                    .overlay
                                    ?.context;
                            if (overlayCtx != null) {
                              Future.microtask(() async {
                                await Future.delayed(
                                    const Duration(milliseconds: 120));
                                try {
                                  final connectivity =
                                      await Connectivity().checkConnectivity();
                                  final offline =
                                      connectivity == ConnectivityResult.none;
                                  if (offline) {
                                    WalletPopup.showNotificationSuccess(
                                      context: overlayCtx,
                                      title: title,
                                      message: const AwText.normal(
                                        'Será sincronizado cuando exista internet',
                                        color: AwColors.white,
                                        size: AwSize.s14,
                                      ),
                                      visibleTime: 3,
                                      isDismissible: true,
                                    );
                                  } else {
                                    WalletPopup.showNotificationSuccess(
                                      context: overlayCtx,
                                      title: title,
                                      visibleTime: 2,
                                      isDismissible: true,
                                    );
                                  }
                                } catch (_) {}
                              });
                            }
                          } catch (_) {}
                        }
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                                  title: const AwText.bold('Eliminar ingreso'),
                                  content: AwText.normal(
                                      '¿Eliminar ingreso de ${DateFormat('MMMM yyyy', 'es').format(dt)}?',
                                      size: AwSize.s14,
                                      color: AwColors.modalGrey),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('Cancelar')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('Eliminar')),
                                  ],
                                ));
                        if (confirm == true) {
                          final date = DateTime(dt.year, dt.month, 1);

                          ref.read(globalLoaderProvider.notifier).state = true;
                          try {
                            final ok = await ctrl.deleteIncomeForDate(date);
                            if (ok) {
                              await ctrl.loadLocalIncomes();
                              try {
                                final overlayCtx =
                                    Navigator.of(context, rootNavigator: true)
                                        .overlay
                                        ?.context;
                                if (overlayCtx != null) {
                                  Future.microtask(() async {
                                    await Future.delayed(
                                        const Duration(milliseconds: 120));
                                    try {
                                      final connectivity = await Connectivity()
                                          .checkConnectivity();
                                      final offline = connectivity ==
                                          ConnectivityResult.none;
                                      if (offline) {
                                        WalletPopup.showNotificationSuccess(
                                          context: overlayCtx,
                                          title: 'Ingreso eliminado',
                                          message: const AwText.normal(
                                            'Será sincronizado cuando exista internet',
                                            color: AwColors.white,
                                            size: AwSize.s14,
                                          ),
                                          visibleTime: 3,
                                          isDismissible: true,
                                        );
                                      } else {
                                        WalletPopup.showNotificationSuccess(
                                          context: overlayCtx,
                                          title: 'Ingreso eliminado',
                                          visibleTime: 2,
                                          isDismissible: true,
                                        );
                                      }
                                    } catch (_) {}
                                  });
                                }
                              } catch (_) {}
                            }
                          } finally {
                            ref.read(globalLoaderProvider.notifier).state =
                                false;
                          }
                        }
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
