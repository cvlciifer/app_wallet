import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:app_wallet/core/providers/profile/ingresos_provider.dart';

class HomeIncomeSummary extends StatelessWidget {
  final WalletExpensesController controller;
  final Color? mainTextColor;

  const HomeIncomeSummary({Key? key, required this.controller, this.mainTextColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return riverpod.Consumer(builder: (ctx, ref, _) {
      final ingresosState = ref.watch(ingresosProvider);
      final now = DateTime.now();
      final selectedMonth =
          controller.monthFilter ?? DateTime(now.year, now.month);

      final id =
          '${selectedMonth.year}${selectedMonth.month.toString().padLeft(2, '0')}';
      final existing = ingresosState.localIncomes[id];
      final fijo =
          existing != null ? (existing['ingreso_fijo'] as int? ?? 0) : 0;
      final imprevisto =
          existing != null ? (existing['ingreso_imprevisto'] as int? ?? 0) : 0;
      final total = fijo + imprevisto;

      final expensesThisMonth = controller.allExpenses
          .where((e) =>
              e.date.year == selectedMonth.year &&
              e.date.month == selectedMonth.month)
          .toList();
      final spent = expensesThisMonth.fold(0.0, (sum, e) => sum + e.amount);

      final available = (total - spent).toDouble();

      return SizedBox(
        width: double.infinity,
        child: LayoutBuilder(builder: (ctx, constraints) {
          final isTight =
              constraints.maxHeight.isFinite && constraints.maxHeight < 150;
          final double textScale = MediaQuery.textScaleFactorOf(ctx);
          // base sizes
          double mainSize = isTight ? 24.0 : 28.0;
          double subSize = isTight ? AwSize.s12 : AwSize.s14;
          // If user has accessibility text scale, reduce sizes proportionally
          if (textScale > 1.0) {
            mainSize = (mainSize / textScale) * 0.95;
            subSize = (subSize / textScale) * 0.95;
          }
          final Widget gapSmallWidget =
              isTight ? AwSpacing.xs : AwSpacing.s6;
          final Widget gapMediumWidget = isTight || textScale > 1.0
              ? AwSpacing.s6
              : AwSpacing.s12;

          if (total == 0 && spent == 0) {
            if (constraints.hasBoundedHeight) {
              return SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        size: 40, color: AwColors.white),
                    AwSpacing.s6,
                    AwText.bold(
                      'Admin Wallet',
                      size: mainSize,
                      color: AwColors.white,
                    ),
                    AwSpacing.s6,
                    Center(
                      child: AwText.normal(
                        'Tu app de gestión financiera',
                        size: subSize,
                        color: AwColors.white,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet,
                    size: 40, color: AwColors.white),
                AwSpacing.s6,
                AwText.bold(
                  'Admin Wallet',
                  size: mainSize,
                  color: AwColors.white,
                ),
                AwSpacing.s6,
                Center(
                  child: AwText.normal(
                    'Tu app de gestión financiera',
                    size: subSize,
                    color: AwColors.white,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              // Main column content centered vertically
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AwText.normal(
                        formatNumber(available),
                        size: mainSize,
                        color: available < 0
                            ? AwColors.red
                            : (mainTextColor ?? AwColors.boldBlack),
                      ),
                    ),
                  ),
                  gapSmallWidget,
                  gapMediumWidget,
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
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: AwText.bold(
                                formatNumber(total.toDouble()),
                                size: subSize,
                                color: AwColors.white,
                                textOverflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
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
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: AwText.bold(
                                formatNumber(spent),
                                size: subSize,
                                color: AwColors.white,
                                textOverflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        }),
      );
    });
  }
}
