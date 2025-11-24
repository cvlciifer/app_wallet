import 'package:app_wallet/library_section/main_library.dart';

class DetailExpenseDialog {
  static void show(BuildContext context, Expense expense,
      {void Function(Expense expense)? onRemoveExpense}) {
    void _showDeleteConfirmation(BuildContext context, Expense expense) {
      showDialog(
        context: context,
        builder: (confirmCtx) => AlertDialog(
          title: const AwText.bold(
            'Eliminar Gasto',
            color: AwColors.red,
          ),
          content: const AwText(
              text: 'Estás a punto de borrar un gasto. ¿Estás seguro?'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: SizedBox(
                      height: AwSize.s48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(confirmCtx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AwColors.blueGrey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AwSize.s16),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Cancelar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AwColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: SizedBox(
                      height: AwSize.s48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(confirmCtx).pop();
                          Navigator.of(context).pop();
                          if (onRemoveExpense != null) onRemoveExpense(expense);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AwColors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AwSize.s16),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Continuar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AwColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: TicketCard(
          roundTopCorners: true,
          topCornerRadius: 10,
          compactNotches: true,
          overlays: [
            Positioned(
              top: -10,
              right: -10,
              child: Material(
                color: Colors.white,
                child: IconButton(
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              left: -10,
              child: Material(
                color: Colors.white,
                child: IconButton(
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete, size: 28),
                  color: AwColors.red,
                  onPressed: () => _showDeleteConfirmation(ctx, expense),
                ),
              ),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AwText.bold(
                'Detalles',
                color: AwColors.blue,
                size: AwSize.s24,
              ),
              DetailExpenseContent(expense: expense),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  WalletButton.textButton(
                    fontSize: AwSize.s18,
                    buttonText: 'Cerrar',
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
