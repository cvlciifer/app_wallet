import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
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
          final available = (total -
                  (wide
                      ? widget.controller.allExpenses
                          .where((e) =>
                              e.date.year == now.year &&
                              e.date.month == now.month)
                          .fold(0.0, (s, e) => s + e.amount)
                      : spent))
              .toDouble();

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                  child: IconButton(
                    padding: const EdgeInsets.all(8),
                    icon:
                        const Icon(Icons.edit, size: 18, color: AwColors.black),
                    onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
                        builder: (_) => const IngresosPage())),
                  ),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AwSpacing.s6,
                  const AwText.bold('Saldo Disponible',
                      size: AwSize.s16, color: AwColors.modalGrey),
                  AwSpacing.s6,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AwText.normal(
                          formatNumber(available),
                          size: 30,
                          color: available < 0
                              ? AwColors.red
                              : (available == 0.0
                                  ? AwColors.appBarColor
                                  : AwColors.boldBlack),
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
                  if (_expanded) ...[
                    const AwDivider(),
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
                        size: AwSize.s14,
                        color:
                            percent > 80 ? AwColors.red : AwColors.modalGrey),
                    AwSpacing.s,
                  ],
                  AwSpacing.s6,
                  Row(
                    children: [
                      Expanded(
                        child: CompactActionButton(
                          text: 'Estadísticas',
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
                                builder: (_) => EstadisticasScreen(
                                    expenses: monthExpenses)));
                          },
                          primary: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CompactActionButton(
                          text: 'Informe',
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
                                    expenses: monthExpenses)));
                          },
                          primary: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
