import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter/material.dart';
import 'package:app_wallet/profile_section/presentation/screens/ingresos_page.dart';
import 'package:app_wallet/core/providers/profile/ingresos_provider.dart';

class HomeIncomeCard extends StatefulWidget {
  final WalletExpensesController controller;
  final bool isWide;

  const HomeIncomeCard(
      {Key? key, required this.controller, this.isWide = false})
      : super(key: key);

  @override
  State<HomeIncomeCard> createState() => _HomeIncomeCardState();
}

class _HomeIncomeCardState extends State<HomeIncomeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return riverpod.Consumer(
      builder: (ctx, ref, _) {
        final ingresosState = ref.watch(ingresosProvider);
        final now = DateTime.now();
        final id = '${now.year}${now.month.toString().padLeft(2, '0')}';
        final existing = ingresosState.localIncomes[id];
        final fijo =
            existing != null ? (existing['ingreso_fijo'] as int? ?? 0) : 0;
        final imprevisto = existing != null
            ? (existing['ingreso_imprevisto'] as int? ?? 0)
            : 0;
        final total = fijo + imprevisto;

        final expensesThisMonth = widget.controller.allExpenses
            .where((e) => e.date.year == now.year && e.date.month == now.month)
            .toList();
        final spent = expensesThisMonth.fold(0.0, (sum, e) => sum + e.amount);
        final percent = total > 0 ? (spent / total * 100) : 0.0;

        Widget buildTicketCard({required bool wide}) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                left: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                right: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
            ),
            child: TicketCard(
              notchDepth: 0,
              roundTopCorners: true,
              elevation: 8,
              color: Colors.white,
              boxShadowAll: true,
              overlays: [
                Positioned(
                  top: -8,
                  right: -8,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      padding: const EdgeInsets.all(8),
                      icon: const Icon(Icons.edit,
                          size: 18, color: AwColors.appBarColor),
                      onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
                          builder: (_) => const IngresosPage())),
                    ),
                  ),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  if (!wide)
                    const AwText.normal('Saldo Disponible',
                        size: AwSize.s18, color: AwColors.modalGrey)
                  else
                    const AwText.bold('Saldo disponible',
                        size: AwSize.s16, color: AwColors.appBarColor),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AwText.bold(
                          formatNumber((total -
                                  (wide
                                      ? widget.controller.allExpenses
                                          .where((e) =>
                                              e.date.year == now.year &&
                                              e.date.month == now.month)
                                          .fold(0.0, (s, e) => s + e.amount)
                                      : spent))
                              .toDouble()),
                          size: wide ? AwSize.s20 : AwSize.s22,
                          color: ((total -
                                          (wide
                                              ? widget.controller.allExpenses
                                                  .where((e) =>
                                                      e.date.year == now.year &&
                                                      e.date.month == now.month)
                                                  .fold(0.0,
                                                      (s, e) => s + e.amount)
                                              : spent))
                                      .toDouble() <
                                  0)
                              ? AwColors.red
                              : (wide
                                  ? AwColors.boldBlack
                                  : AwColors.appBarColor),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: IconButton(
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _expanded ? Icons.expand_less : Icons.expand_more,
                            color: AwColors.modalGrey,
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => _expanded = !_expanded),
                        ),
                      ),
                    ],
                  ),
                  AwSpacing.xs,
                  if (_expanded) ...[
                    AwSpacing.s6,
                    const Divider(),
                    AwSpacing.s6,
                    AwText.normal(
                        'Ingreso mensual: ${formatNumber(fijo.toDouble())}',
                        size: AwSize.s14,
                        color: AwColors.modalGrey),
                    AwSpacing.s6,
                    AwText.normal(
                        'Ingreso imprevisto: ${formatNumber(imprevisto.toDouble())}',
                        size: AwSize.s14,
                        color: AwColors.modalGrey),
                    AwSpacing.s,
                    AwText.normal(
                        'Gasto este mes: ${formatNumber(spent)} • ${percent.toStringAsFixed(0)}% del ingreso',
                        size: AwSize.s12,
                        color:
                            percent > 80 ? AwColors.red : AwColors.modalGrey),
                    AwSpacing.s,
                  ],
                  AwSpacing.s6,
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AwSize.s40,
                          child: OutlinedButton(
                            onPressed: () {
                              final now = DateTime.now();
                              final target = widget.controller.monthFilter ??
                                  DateTime(now.year, now.month);

                              final monthExpenses = widget
                                  .controller.allExpenses
                                  .where((e) =>
                                      e.date.year == target.year &&
                                      e.date.month == target.month)
                                  .toList();

                              Navigator.of(ctx).push(MaterialPageRoute(
                                  builder: (_) => EstadisticasScreen(
                                        expenses: monthExpenses,
                                      )));
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AwColors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AwSize.s16),
                              ),
                            ),
                            child: const Center(
                              child: AwText.bold(
                                'Estadísticas',
                                size: AwSize.s14,
                                color: AwColors.blue,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: WalletButton.primaryButton(
                          buttonText: 'Informe',
                          onPressed: () {
                            final now = DateTime.now();
                            final target = widget.controller.monthFilter ??
                                DateTime(now.year, now.month);

                            final monthExpenses = widget.controller.allExpenses
                                .where((e) =>
                                    e.date.year == target.year &&
                                    e.date.month == target.month)
                                .toList();

                            Navigator.of(ctx).push(MaterialPageRoute(
                                builder: (_) => InformeMensualScreen(
                                      expenses: monthExpenses,
                                    )));
                          },
                          height: AwSize.s40,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        }

        // Return depending on width
        if (!widget.isWide) {
          return Column(
            children: [
              buildTicketCard(wide: false),
              const SizedBox(height: 24),
            ],
          );
        }

        return Column(
          children: [
            buildTicketCard(wide: true),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
