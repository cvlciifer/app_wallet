import 'package:app_wallet/library/main_library.dart';
import 'package:app_wallet/components/widgets/expense_form/expense_form.dart';

class NewExpenseScreen extends StatefulWidget {
  const NewExpenseScreen({super.key});

  @override
  State<NewExpenseScreen> createState() {
    return _NewExpenseScreenState();
  }
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    userEmail = _auth.currentUser?.email;
  }

  Future<void> createExpense(Expense expense) async {
    if (userEmail != null) {
      await db.collection('usuarios').doc('Gastos').collection(userEmail!).add({
        'name': expense.title,
        'fecha': Timestamp.fromDate(expense.date),
        'cantidad': expense.amount,
        'tipo': expense.category.toString().split('.').last,
      });
    } else {
      print('Error: El email del usuario no está disponible.');
    }
  }

  void _handleExpenseSubmit(Expense expense) async {
    try {
      await createExpense(expense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AwText.bold(
              'Gasto agregado exitosamente',
              color: AwColors.white,
            ),
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
            content: AwText.bold(
              'Error al agregar gasto: $error',
              color: AwColors.white,
            ),
            backgroundColor: AwColors.red,
          ),
        );
      }
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
