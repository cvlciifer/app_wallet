import 'package:app_wallet/library_section/main_library.dart';

class DetailExpenseDialog {
  static void show(BuildContext context, Expense expense) {
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
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AwText.bold(
                'Detalles del Gasto',
                color: AwColors.blue,
                size: AwSize.s24,
              ),
              const SizedBox(height: 12),
              DetailExpenseContent(expense: expense),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  WalletButton.textButton(
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
