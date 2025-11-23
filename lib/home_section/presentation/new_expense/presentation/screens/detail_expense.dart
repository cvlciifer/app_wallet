import 'package:app_wallet/library_section/main_library.dart';

class DetailExpenseDialog {
  static void show(BuildContext context, Expense expense, {void Function(Expense expense)? onRemoveExpense}) {
    void _showDeleteConfirmation(BuildContext context, Expense expense) {
      showDialog(
        context: context,
        builder: (confirmCtx) => AlertDialog(
          title: const AwText.bold(
            'Eliminar Gasto',
            color: AwColors.red,
          ),
          content: const AwText(text: 'Estás a punto de borrar un gasto. ¿Estás seguro?'),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                WalletButton.primaryButton(
                  buttonText: 'Cancelar',
                  onPressed: () => Navigator.of(confirmCtx).pop(),
                ),
                const SizedBox(width: 8),
                WalletButton.primaryButton(
                  buttonText: 'Continuar',
                  onPressed: () {
                    Navigator.of(confirmCtx).pop();
                    Navigator.of(context).pop();
                    if (onRemoveExpense != null) onRemoveExpense(expense);
                  },
                  backgroundColor: AwColors.red,
                ),
              ],
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
