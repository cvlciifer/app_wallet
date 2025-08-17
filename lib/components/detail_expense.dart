import 'package:app_wallet/library/main_library.dart';

class DetailExpenseDialog {
  static void show(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AwText.bold(
          'Detalles del Gasto',
          color: AwColors.blue,
          size: AwSize.s24,
        ),
        content: AwSpacing.box300(
          child:
              DetailExpenseContent(expense: expense), // Usa el widget separado
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          AwButton(
            label: 'Cerrar',
            onPressed: () => Navigator.of(ctx).pop(),
            bold: true,
          ),
        ],
      ),
    );
  }
}
