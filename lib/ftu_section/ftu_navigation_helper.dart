import 'package:app_wallet/library_section/main_library.dart';
import 'dart:math' as math;

class FTUNavigationHelper {
  static Future<void> showStatisticsFTU(
    BuildContext context,
    GlobalKey statisticsButtonKey,
    List<Expense> allExpenses,
  ) async {
    try {
      if (!context.mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));

      final ctx = statisticsButtonKey.currentContext;
      if (ctx == null) return;

      try {
        await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 1.0);
      } catch (_) {}

      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;

      final targetPos = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;

      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'statistics_ftu',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, a1, a2) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: HolePainter(
                      holeRect: Rect.fromLTWH(
                        targetPos.dx - 8,
                        targetPos.dy - 8,
                        targetSize.width + 16,
                        targetSize.height + 16,
                      ),
                      borderRadius: 8,
                      overlayColor: AwColors.black.withOpacity(0.45),
                    ),
                  ),
                ),
                Positioned(
                  left: targetPos.dx - 8,
                  top: targetPos.dy - 8,
                  child: Container(
                    width: targetSize.width + 16,
                    height: targetSize.height + 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AwColors.appBarColor, width: 3),
                    ),
                  ),
                ),
                Positioned(
                  left: (() {
                    final screenW = MediaQuery.of(context).size.width;
                    final popupW = math.min(320, screenW - 32);
                    return (screenW - popupW) / 2;
                  })(),
                  top: (() {
                    const popupApproxH = 160.0;
                    final preferAbove = targetPos.dy - popupApproxH - 12;
                    if (preferAbove >= 16) return preferAbove;
                    return 16.0;
                  })(),
                  child: Container(
                    width: math.min(320, MediaQuery.of(context).size.width - 32),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AwColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AwColors.black.withOpacity(0.18), blurRadius: 8)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AwText.bold('Estadísticas', size: AwSize.s14),
                        AwSpacing.s6,
                        const AwText.normal(
                            'Presiona este botón para ver gráficos de tus gastos. Podrás filtrar por categoría y subcategoría.',
                            size: AwSize.s12,
                            color: AwColors.modalGrey),
                        AwSpacing.s10,
                        Row(
                          children: [
                            Expanded(
                              child: WalletButton.primaryButton(
                                buttonText: 'Ir a Estadísticas',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  try {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => EstadisticasScreen(
                                          expenses: allExpenses,
                                        ),
                                        settings: const RouteSettings(arguments: {'showFTUOnStatistics': true}),
                                      ),
                                    );
                                  } catch (_) {}
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {}
  }

  static Future<void> showInformesFTU(
    BuildContext context,
    GlobalKey informesButtonKey,
    List<Expense> allExpenses,
  ) async {
    try {
      if (!context.mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));

      final ctx = informesButtonKey.currentContext;
      if (ctx == null) return;

      try {
        await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 1.0);
      } catch (_) {}

      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;

      final targetPos = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;

      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'informes_ftu',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, a1, a2) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: HolePainter(
                      holeRect: Rect.fromLTWH(
                        targetPos.dx - 8,
                        targetPos.dy - 8,
                        targetSize.width + 16,
                        targetSize.height + 16,
                      ),
                      borderRadius: 8,
                      overlayColor: AwColors.black.withOpacity(0.45),
                    ),
                  ),
                ),
                Positioned(
                  left: targetPos.dx - 8,
                  top: targetPos.dy - 8,
                  child: Container(
                    width: targetSize.width + 16,
                    height: targetSize.height + 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AwColors.appBarColor, width: 3),
                    ),
                  ),
                ),
                Positioned(
                  left: (() {
                    final screenW = MediaQuery.of(context).size.width;
                    final popupW = math.min(320, screenW - 32);
                    return (screenW - popupW) / 2;
                  })(),
                  top: (() {
                    const popupApproxH = 160.0;
                    final preferAbove = targetPos.dy - popupApproxH - 12;
                    if (preferAbove >= 16) return preferAbove;
                    return 16.0;
                  })(),
                  child: Container(
                    width: math.min(320, MediaQuery.of(context).size.width - 32),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AwColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AwColors.black.withOpacity(0.18), blurRadius: 8)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AwText.bold('Informes Mensuales', size: AwSize.s14),
                        AwSpacing.s6,
                        const AwText.normal(
                            'Ahora veremos la pantalla de informes mensuales organizados por categorías y subcategorías.',
                            size: AwSize.s12,
                            color: AwColors.modalGrey),
                        AwSpacing.s10,
                        Row(
                          children: [
                            Expanded(
                              child: WalletButton.primaryButton(
                                buttonText: 'Ir a Informes',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  try {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => InformeMensualScreen(
                                          expenses: allExpenses,
                                        ),
                                      ),
                                    );
                                  } catch (_) {}
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {}
  }

  static Future<void> showMiWalletFTU(
    BuildContext context,
    GlobalKey miWalletButtonKey,
  ) async {
    try {
      if (!context.mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));

      final ctx = miWalletButtonKey.currentContext;
      if (ctx == null) return;

      try {
        await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 1.0);
      } catch (_) {}

      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;

      final targetPos = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;

      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'miwallet_ftu',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, a1, a2) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: HolePainter(
                      holeRect: Rect.fromLTWH(
                        targetPos.dx - 8,
                        targetPos.dy - 8,
                        targetSize.width + 16,
                        targetSize.height + 16,
                      ),
                      borderRadius: 8,
                      overlayColor: AwColors.black.withOpacity(0.45),
                    ),
                  ),
                ),
                Positioned(
                  left: targetPos.dx - 8,
                  top: targetPos.dy - 8,
                  child: Container(
                    width: targetSize.width + 16,
                    height: targetSize.height + 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AwColors.appBarColor, width: 3),
                    ),
                  ),
                ),
                Positioned(
                  left: (() {
                    final screenW = MediaQuery.of(context).size.width;
                    final popupW = math.min(320, screenW - 32);
                    return (screenW - popupW) / 2;
                  })(),
                  top: (() {
                    const popupApproxH = 160.0;
                    final preferAbove = targetPos.dy - popupApproxH - 12;
                    if (preferAbove >= 16) return preferAbove;
                    return 16.0;
                  })(),
                  child: Container(
                    width: math.min(320, MediaQuery.of(context).size.width - 32),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AwColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AwColors.black.withOpacity(0.18), blurRadius: 8)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AwText.bold('Mi Wallet', size: AwSize.s14),
                        AwSpacing.s6,
                        const AwText.normal('Presiona este botón para acceder a tu perfil, ingresos y configuración.',
                            size: AwSize.s12, color: AwColors.modalGrey),
                        AwSpacing.s10,
                        Row(
                          children: [
                            Expanded(
                              child: WalletButton.primaryButton(
                                buttonText: 'Ir a Mi Wallet',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  try {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => const WalletProfilePage(),
                                        settings: const RouteSettings(arguments: {'showProfileFTU': true}),
                                      ),
                                    );
                                  } catch (_) {}
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {}
  }
}
