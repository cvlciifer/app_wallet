import 'package:app_wallet/library_section/main_library.dart';

/// Muestra un diálogo centrado con dos tarjetas animadas (rebote).
///
/// Llama a [onAddExpense] cuando se selecciona la tarjeta "Agregar gasto" y
/// a [onAddRecurrent] cuando se selecciona "Agregar gasto Recurrente".
Future<void> showTwoOptionsDialog(
  BuildContext context, {
  required VoidCallback onAddExpense,
  required VoidCallback onAddRecurrent,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Opciones',
    pageBuilder: (ctx, a1, a2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      // top: aparece desde arriba con rebote
      final topOffset = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.8, curve: Curves.elasticOut)));
      // bottom: aparece desde abajo con rebote (ligeramente escalonado)
      final bottomOffset = Tween<Offset>(begin: const Offset(0, 1.2), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: const Interval(0.1, 1.0, curve: Curves.elasticOut)));

      return Material(
        color: Colors.black45,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await Future.delayed(const Duration(milliseconds: 50));
                        try {
                          onAddExpense();
                        } catch (_) {}
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 80,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Icon(Icons.add, color: AwColors.appBarColor),
                              AwSpacing.m,
                              AwText.bold('Agregar gasto', color: AwColors.boldBlack),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AwSpacing.s12,
                // Separator with white lines and centered 'O'
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: Container(height: 1, color: AwColors.white)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Container(
                          color: Colors.black45,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: const AwText.bold('O', color: AwColors.white),
                        ),
                      ),
                      Expanded(child: Container(height: 1, color: AwColors.white)),
                    ],
                  ),
                ),
                AwSpacing.s12,
                SlideTransition(
                  position: bottomOffset,
                  child: Card(
                    color: AwColors.white,
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await Future.delayed(const Duration(milliseconds: 50));
                        try {
                          onAddRecurrent();
                        } catch (_) {}
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 80,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Icon(Icons.repeat, color: AwColors.appBarColor),
                              AwSpacing.m,
                              AwText.bold('Agregar gasto Recurrente', color: AwColors.boldBlack),
                            ],
                          ),
                        ),
                      ),
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
