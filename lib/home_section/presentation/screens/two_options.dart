import 'package:app_wallet/library_section/main_library.dart';
import '../../../ftu_section/ftu_two_options.dart';

Future<void> showTwoOptionsDialog(
  BuildContext context, {
  required Future<void> Function() onAddExpense,
  required Future<void> Function() onAddRecurrent,
  bool showFTUOnOpen = false,
  Set<String> completedOptions = const {},
  VoidCallback? onFTUComplete,
}) {
  // Si showFTUOnOpen es true, mostrar el FTU controlado en lugar del diálogo normal
  if (showFTUOnOpen) {
    return showFTUTwoOptions(
      context,
      onAddExpense: onAddExpense,
      onAddRecurrent: onAddRecurrent,
      onFTUComplete: onFTUComplete ?? () {},
    );
  }

  bool _didPop = false;
  final GlobalKey _firstCardKey = GlobalKey();
  final GlobalKey _secondCardKey = GlobalKey();
  final BuildContext popupCtx = Navigator.of(context, rootNavigator: true).overlay?.context ?? context;

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Opciones',
    pageBuilder: (ctx, a1, a2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final topOffset = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.8, curve: Curves.elasticOut)));
      final bottomOffset = Tween<Offset>(begin: const Offset(0, 1.2), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: const Interval(0.1, 1.0, curve: Curves.elasticOut)));

      return Material(
        color: AwColors.black45,
        child: Center(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SlideTransition(
                  position: topOffset,
                  child: Card(
                    key: _firstCardKey,
                    color: AwColors.white,
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        if (_didPop) return;
                        _didPop = true;
                        Navigator.of(popupCtx).pop();
                        await Future.delayed(const Duration(milliseconds: 50));
                        try {
                          await onAddExpense();
                        } catch (_) {}
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 85,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: AwColors.appBarColor),
                              AwSpacing.m,
                              Expanded(
                                child: AwText.bold(
                                  'Agregar gasto',
                                  color: AwColors.boldBlack,
                                  maxLines: 2,
                                  textOverflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (completedOptions.contains('expense')) ...[
                                AwSpacing.m,
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration:
                                      BoxDecoration(color: AwColors.greyLight, borderRadius: BorderRadius.circular(8)),
                                  child: const AwText.bold('Completado', color: AwColors.boldBlack),
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AwSpacing.s12,
                SlideTransition(
                  position: bottomOffset,
                  child: Card(
                    key: _secondCardKey,
                    color: AwColors.white,
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: completedOptions.contains('recurrent')
                          ? null
                          : () async {
                              if (_didPop) return;
                              _didPop = true;
                              Navigator.of(popupCtx).pop();
                              await Future.delayed(const Duration(milliseconds: 50));
                              try {
                                await onAddRecurrent();
                              } catch (_) {}
                            },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 85,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.repeat, color: AwColors.appBarColor),
                              AwSpacing.m,
                              Expanded(
                                child: AwText.bold(
                                  'Agregar gasto Recurrente',
                                  color: AwColors.boldBlack,
                                  maxLines: 2,
                                  textOverflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (completedOptions.contains('recurrent')) ...[
                                AwSpacing.m,
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration:
                                      BoxDecoration(color: AwColors.greyLight, borderRadius: BorderRadius.circular(8)),
                                  child: const AwText.bold('Completado', color: AwColors.boldBlack),
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AwSpacing.s30,
                SlideTransition(
                  position: bottomOffset,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      if (_didPop) return;
                      _didPop = true;
                      Navigator.of(popupCtx).pop();
                      await Future.delayed(const Duration(milliseconds: 50));
                    },
                    child: const CircleAvatar(
                      backgroundColor: AwColors.greyLight,
                      radius: 20,
                      child: Icon(Icons.close, size: 20, color: AwColors.appBarColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 700),
  );
}
