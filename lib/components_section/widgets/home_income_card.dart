import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:app_wallet/profile_section/presentation/screens/ingresos_page.dart';
import 'package:app_wallet/core/providers/profile/ingresos_provider.dart';
import 'package:app_wallet/components_section/components/ticket_card_home.dart';

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
  @override
  Widget build(BuildContext context) {
    return riverpod.Consumer(
      builder: (ctx, ref, _) {
        final ingresosState = ref.watch(ingresosProvider);
        final now = DateTime.now();
        final selectedMonth =
            widget.controller.monthFilter ?? DateTime(now.year, now.month);

        final id =
            '${selectedMonth.year}${selectedMonth.month.toString().padLeft(2, '0')}';
        final existing = ingresosState.localIncomes[id];
        final fijo =
            existing != null ? (existing['ingreso_fijo'] as int? ?? 0) : 0;
        final imprevisto = existing != null
            ? (existing['ingreso_imprevisto'] as int? ?? 0)
            : 0;
        final total = fijo + imprevisto;

        final expensesThisMonth = widget.controller.allExpenses
            .where((e) =>
                e.date.year == selectedMonth.year &&
                e.date.month == selectedMonth.month)
            .toList();
        final spent = expensesThisMonth.fold(0.0, (sum, e) => sum + e.amount);

        Widget buildTicketCard({required bool wide}) {
          final available = (total -
                  (wide
                      ? widget.controller.allExpenses
                          .where((e) =>
                              e.date.year == selectedMonth.year &&
                              e.date.month == selectedMonth.month)
                          .fold(0.0, (s, e) => s + e.amount)
                      : spent))
              .toDouble();

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
            ),
            child: TicketCardHome(
              elevation: 8,
              color: Colors.white,
              borderRadius: 28,
              shadowOpacity: 0.26,
              overlays: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    padding: const EdgeInsets.all(8),
                    icon:
                        const Icon(Icons.edit, size: 18, color: AwColors.black),
                    onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
                        builder: (_) => const IngresosPage())),
                  ),
                ),
              ],
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: AwText.bold('Saldo Disponible',
                              size: AwSize.s16, color: AwColors.modalGrey),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Balance centered
                    Center(
                      child: AwText.normal(
                        formatNumber(available),
                        size: 30, // keep as requested
                        color:
                            available < 0 ? AwColors.red : AwColors.boldBlack,
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 8),

                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AwText.normal(
                                  'Ingresos de ${toBeginningOfSentenceCase(DateFormat('MMMM', 'es').format(selectedMonth))}',
                                  size: AwSize.s12,
                                  color: AwColors.modalGrey),
                              AwSpacing.xs,
                              AwText.bold(formatNumber(total.toDouble()),
                                  size: AwSize.s16, color: AwColors.green),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AwText.normal(
                                  'Gastos de ${toBeginningOfSentenceCase(DateFormat('MMMM', 'es').format(selectedMonth))}',
                                  size: AwSize.s12,
                                  color: AwColors.modalGrey),
                              AwSpacing.xs,
                              AwText.bold(formatNumber(spent),
                                  size: AwSize.s14, color: AwColors.red),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          );
        }

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
