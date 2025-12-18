import 'dart:developer';

import 'package:app_wallet/library_section/main_library.dart';

class NewExpenseScreen extends StatefulWidget {
  final Expense? initialExpense;

  const NewExpenseScreen({super.key, this.initialExpense});

  @override
  State<NewExpenseScreen> createState() {
    return _NewExpenseScreenState();
  }
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  @override
  void initState() {
    super.initState();
  }

  bool _shouldRunFTU = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['showFTUOnNewExpense'] == true) {
        _shouldRunFTU = true;
      }
    } catch (_) {}
  }

  void _handleExpenseSubmit(Expense expense) async {
    try {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return AlertDialog(
              title: const AwText.bold(
                'Gasto preparado',
                color: AwColors.black,
              ),
              content: const AwText(text: 'El gasto está listo para guardarse.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const AwText.bold('Aceptar', color: AwColors.blue),
                ),
              ],
            );
          },
        );
        if (mounted) Navigator.pop(context, expense);
      }
    } catch (error) {
      if (mounted) {
        WalletPopup.showNotificationError(context: context, title: 'Error al agregar gasto: $error');
      }
      log('Error al agregar gasto: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold(
          'Nuevo Gasto',
          color: AwColors.white,
        ),
        showBackArrow: true,
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 24, 16, keyboardSpace + 16),
            child: ExpenseForm(
              onSubmit: _handleExpenseSubmit,
              initialExpense: widget.initialExpense,
              showFTUOnOpen: _shouldRunFTU,
            ),
          );
        },
      ),
    );
  }
}
