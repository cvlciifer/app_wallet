import 'package:app_wallet/library_section/main_library.dart';

Future<void> showTwoOptionsDialog(
  BuildContext context, {
  required VoidCallback onAddExpense,
  required VoidCallback onAddRecurrent,
}) {
  bool _didPop = false;
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Opciones',
    pageBuilder: (ctx, a1, a2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final topOffset =
          Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero).animate(
              CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.8, curve: Curves.elasticOut)));
      final bottomOffset =
          Tween<Offset>(begin: const Offset(0, 1.2), end: Offset.zero).animate(
              CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.1, 1.0, curve: Curves.elasticOut)));

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
                    color: AwColors.white,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        if (_didPop) return;
                        _didPop = true;
                        Navigator.of(context).pop();
                        await Future.delayed(const Duration(milliseconds: 50));
                        try {
                          onAddExpense();
                        } catch (_) {}
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
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
                    color: AwColors.white,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        if (_didPop) return;
                        _didPop = true;
                        Navigator.of(context).pop();
                        await Future.delayed(const Duration(milliseconds: 50));
                        try {
                          onAddRecurrent();
                        } catch (_) {}
                      },
                      child: const Padding(
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
                      Navigator.of(context).pop();
                      await Future.delayed(const Duration(milliseconds: 50));
                    },
                    child: const CircleAvatar(
                      backgroundColor: AwColors.greyLight,
                      radius: 20,
                      child: Icon(Icons.close,
                          size: 20, color: AwColors.appBarColor),
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
