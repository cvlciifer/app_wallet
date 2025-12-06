import 'package:app_wallet/library_section/main_library.dart';

Future<void> showFTUTwoOptions(
  BuildContext context, {
  required Future<void> Function() onAddExpense,
  required Future<void> Function() onAddRecurrent,
  required VoidCallback onFTUComplete,
  String initialStep = 'expense',
}) async {
  String currentStep = initialStep;
  bool _isNavigating = false;

  Future<void> _showStep(String step) async {
    if (_isNavigating) return;

    final GlobalKey _activeCardKey = GlobalKey();
    final BuildContext dialogContext = context;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'FTU Two Options',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, a1, a2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final topOffset = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.8, curve: Curves.elasticOut)));
        final bottomOffset = Tween<Offset>(begin: const Offset(0, 1.2), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: const Interval(0.1, 1.0, curve: Curves.elasticOut)));

        final bool isExpenseStep = step == 'expense';
        final Widget activeCard = _buildCard(
          key: _activeCardKey,
          icon: isExpenseStep ? Icons.add : Icons.repeat,
          title: isExpenseStep ? 'Agregar gasto' : 'Agregar gasto Recurrente',
          isActive: true,
          onTap: () async {
            if (_isNavigating) return;
            _isNavigating = true;
            Navigator.of(ctx).pop();
            await Future.delayed(const Duration(milliseconds: 100));

            try {
              if (isExpenseStep) {
                await onAddExpense();

                await _showStep('recurrent');
              } else {
                await onAddRecurrent();

                onFTUComplete();
              }
            } catch (e) {
              _isNavigating = false;
            }
          },
        );

        final Widget disabledCard = _buildCard(
          icon: isExpenseStep ? Icons.repeat : Icons.add,
          title: isExpenseStep ? 'Agregar gasto Recurrente' : 'Agregar gasto',
          isActive: false,
          onTap: null,
        );

        return Material(
          color: AwColors.black.withOpacity(0.75),
          child: Center(
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AwColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: AwColors.black.withOpacity(0.06), blurRadius: 6)],
                      ),
                      child: Column(
                        children: [
                          AwText.bold(
                            isExpenseStep ? 'Paso 1 de 2' : 'Paso 2 de 2',
                            color: AwColors.appBarColor,
                            size: AwSize.s12,
                          ),
                          AwSpacing.s6,
                          AwText.normal(
                            isExpenseStep
                                ? 'Primero, completa el flujo de "Agregar gasto"'
                                : 'Ahora, completa el flujo de "Agregar gasto Recurrente"',
                            color: AwColors.appBarColor,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpenseStep) ...[
                    SlideTransition(position: topOffset, child: activeCard),
                    AwSpacing.s12,
                    SlideTransition(position: bottomOffset, child: disabledCard),
                  ] else ...[
                    SlideTransition(position: topOffset, child: disabledCard),
                    AwSpacing.s12,
                    SlideTransition(position: bottomOffset, child: activeCard),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 700),
    );
  }

  await _showStep(currentStep);
}

Widget _buildCard({
  GlobalKey? key,
  required IconData icon,
  required String title,
  required bool isActive,
  required VoidCallback? onTap,
}) {
  return Card(
    key: key,
    color: isActive ? AwColors.white : AwColors.greyLight.withOpacity(0.5),
    elevation: isActive ? 10 : 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: isActive ? BorderSide(color: AwColors.appBarColor, width: 3) : BorderSide.none,
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 85,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? AwColors.appBarColor : AwColors.modalGrey,
              ),
              AwSpacing.m,
              Expanded(
                child: AwText.bold(
                  title,
                  color: isActive ? AwColors.boldBlack : AwColors.modalGrey,
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive) ...[
                AwSpacing.m,
                Icon(Icons.arrow_forward, color: AwColors.appBarColor),
              ]
            ],
          ),
        ),
      ),
    ),
  );
}
