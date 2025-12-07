import 'package:app_wallet/library_section/main_library.dart';
import 'dart:math' as math;

class FTUIncomeHelper {
  static Future<void> maybeShowFirstTimeIncome(
    BuildContext context,
    GlobalKey editIconKey,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('first_time_income_shown') ?? false;
      final rejected = prefs.getBool('ftu_rejected') ?? false;

      // Si el usuario rechazó el FTU, no mostrar nada
      if (rejected || shown) return;

      final onboardingShown = prefs.getBool('first_time_onboarding_shown') ?? false;
      if (!onboardingShown && context.mounted) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => const FirstTimeOnboardingDialog(),
        );

        // Si el usuario rechazó, salir inmediatamente
        if (result == false) {
          return;
        }

        if (result == true) {
          try {
            await prefs.setBool('first_time_onboarding_shown', true);
          } catch (_) {}
        }
      }
      if (!context.mounted) return;
      await Future.delayed(const Duration(milliseconds: 400));

      final ctx = editIconKey.currentContext;
      if (ctx == null) return;
      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;

      final targetPos = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;

      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'first_time_income',
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
                      borderRadius: 40,
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
                      borderRadius: BorderRadius.circular(40),
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
                    final screenH = MediaQuery.of(context).size.height;

                    final preferTop = targetPos.dy + targetSize.height + 12;

                    final maxTop = screenH - 160;
                    return preferTop > maxTop ? maxTop : preferTop;
                  })(),
                  child: Container(
                    width: math.min(320, MediaQuery.of(context).size.width - 32),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AwColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: AwColors.black.withOpacity(0.18), blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AwText.bold('Ingresa tu Monto mensual', size: AwSize.s14),
                        AwSpacing.s6,
                        const AwText.normal('Pulsa el lápiz para configurar tu ingreso mensual.',
                            size: AwSize.s12, color: AwColors.modalGrey),
                        AwSpacing.s10,
                        Row(
                          children: [
                            Expanded(
                              child: WalletButton.primaryButton(
                                buttonText: 'Abrir',
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  try {
                                    await prefs.setBool('first_time_income_shown', true);
                                  } catch (_) {}
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => const IngresosPage(),
                                    settings: const RouteSettings(arguments: {'showFTUOnIngresos': true}),
                                  ));
                                },
                              ),
                            ),
                            AwSpacing.w12,
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
