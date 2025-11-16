import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:app_wallet/core/providers/profile/ingresos_provider.dart';

class HomeIncomeSummary extends StatelessWidget {
  final WalletExpensesController controller;

  const HomeIncomeSummary({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return riverpod.Consumer(builder: (ctx, ref, _) {
      final ingresosState = ref.watch(ingresosProvider);
      final now = DateTime.now();
      final selectedMonth = controller.monthFilter ?? DateTime(now.year, now.month);

      final id = '${selectedMonth.year}${selectedMonth.month.toString().padLeft(2, '0')}';
      final existing = ingresosState.localIncomes[id];
      final fijo = existing != null ? (existing['ingreso_fijo'] as int? ?? 0) : 0;
      final imprevisto = existing != null ? (existing['ingreso_imprevisto'] as int? ?? 0) : 0;
      final total = fijo + imprevisto;

      final expensesThisMonth = controller.allExpenses
          .where((e) => e.date.year == selectedMonth.year && e.date.month == selectedMonth.month)
          .toList();
      final spent = expensesThisMonth.fold(0.0, (sum, e) => sum + e.amount);

      final available = (total - spent).toDouble();

      return SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            // Main column content centered vertically
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: AwText.normal(
                    formatNumber(available),
                    size: 28,
                    color: available < 0 ? AwColors.red : (available == 0.0 ? AwColors.appBarColor : AwColors.white),
                  ),
                ),
                AwSpacing.s6,
                AwSpacing.s12,
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AwText.normal(
                            'Ingresos',
                            size: AwSize.s12,
                            color: AwColors.white,
                          ),
                          AwSpacing.xs,
                          AwText.bold(
                            formatNumber(total.toDouble()),
                            size: AwSize.s14,
                            color: AwColors.white,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const AwText.normal(
                            'Gastos',
                            size: AwSize.s12,
                            color: AwColors.white,
                          ),
                          AwSpacing.xs,
                          AwText.bold(
                            formatNumber(spent),
                            size: AwSize.s14,
                            color: AwColors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
