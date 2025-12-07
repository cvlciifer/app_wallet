import 'package:app_wallet/library_section/main_library.dart';
import 'dart:math' as math;

class FTUAddHelper {
  static Future<void> maybeShowAddFTU(
    BuildContext context,
    GlobalKey fabKey,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('first_time_add_shown') ?? false;
      final rejected = prefs.getBool('ftu_rejected') ?? false;

      // Si el usuario rechazó el FTU o ya lo vio, no mostrar nada
      if (rejected || shown) return;
      if (!context.mounted) return;
      await Future.delayed(const Duration(milliseconds: 150));

      final ctx = fabKey.currentContext;
      if (ctx == null) return;
      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;

      final targetPos = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;

      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'first_time_add',
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
                    const popupApproxH = 140.0;
                    final preferAbove = targetPos.dy - popupApproxH - 12;
                    if (preferAbove >= 16) return preferAbove;
                    final preferBelow = targetPos.dy + targetSize.height + 12;
                    final maxTop = screenH - popupApproxH;
                    return preferBelow > maxTop ? maxTop : preferBelow;
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
                        const AwText.bold('Agregar gasto', size: AwSize.s14),
                        AwSpacing.s6,
                        const AwText.normal('Cuando presiones el botón + vas a poder ver las dos opciones disponibles.',
                            size: AwSize.s12, color: AwColors.modalGrey),
                        AwSpacing.s10,
                        Row(
                          children: [
                            Expanded(
                              child: WalletButton.primaryButton(
                                buttonText: 'Mostrar opciones',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  try {
                                    prefs.setBool('first_time_add_shown', true);
                                  } catch (_) {}
                                  try {
                                    final popupCtx =
                                        Navigator.of(context, rootNavigator: true).overlay?.context ?? context;
                                    final done = <String>{};

                                    void openOptions() {
                                      try {
                                        showTwoOptionsDialog(
                                          context,
                                          showFTUOnOpen: true,
                                          completedOptions: done,
                                          onAddExpense: () async {
                                            try {
                                              final res = await Navigator.of(popupCtx).push<String>(
                                                  MaterialPageRoute(builder: (_) => const FTUAddExpensePage()));
                                              if (res == 'expense') done.add('expense');
                                            } catch (_) {}
                                            if (done.length < 2) {
                                              Future.delayed(const Duration(milliseconds: 120), () => openOptions());
                                            }
                                          },
                                          onAddRecurrent: () async {
                                            try {
                                              final res = await Navigator.of(popupCtx).push<String>(
                                                  MaterialPageRoute(builder: (_) => const FTUAddRecurrentPage()));
                                              if (res == 'recurrent') done.add('recurrent');
                                            } catch (_) {}
                                            if (done.length < 2) {
                                              Future.delayed(const Duration(milliseconds: 120), () => openOptions());
                                            }
                                          },
                                        );
                                      } catch (_) {}
                                    }

                                    openOptions();
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
