import 'dart:developer';

import 'package:app_wallet/library/main_library.dart';
import 'package:app_wallet/components/widgets/expense_form/expense_form.dart';
import 'package:app_wallet/service_db_local/local_crud.dart';

class NewExpenseScreen extends StatefulWidget {
  const NewExpenseScreen({super.key});

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

  void _handleExpenseSubmit(Expense expense) async {
    try {
      await createExpenseLocal(expense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar de vuelta y pasar el expense como resultado
        Navigator.pop(context, expense);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar gasto: $error'),
            backgroundColor: AwColors.red,
          ),
          
        );
        
      }
      log('Error al agregar gasto: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
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
            ),
          );
        },
      ),
    );
  }
}
