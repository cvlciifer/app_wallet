import 'package:app_wallet/library/main_library.dart';

// Formateador de entrada personalizado
class CustomLengthTextInputFormatter extends TextInputFormatter {
  final int maxLength;

  CustomLengthTextInputFormatter(this.maxLength);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Comprueba la longitud del nuevo valor
    if (newValue.text.length > maxLength) {
      // Si es mayor que el límite, devuelve el valor antiguo
      return oldValue;
    }
    return newValue;
  }
}

class NewExpenseScreen extends StatefulWidget {
  const NewExpenseScreen({super.key});

  @override
  State<NewExpenseScreen> createState() {
    return _NewExpenseScreenState();
  }
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  Category _selectedCategory = Category.ocio;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    userEmail = _auth.currentUser?.email;
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now,
    );
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _showDialog() {
    final dialogContent = Platform.isIOS
        ? CupertinoAlertDialog(
            title: const Text('Entrada no válida'),
            content: const Text(
                'Asegúrese de ingresar un título, monto, fecha y categoría válidos.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Ok'),
              ),
            ],
          )
        : AlertDialog(
            title: const Text('Entrada no válida'),
            content: const Text(
                'Asegúrese de ingresar un título, monto, fecha y categoría válidos.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Ok'),
              ),
            ],
          );

    showDialog(context: context, builder: (ctx) => dialogContent);
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

  void _submitExpenseData() async {
    final enteredAmount = int.tryParse(_amountController.text.trim());
    final amountIsInvalid = enteredAmount == null ||
        enteredAmount <= 0 ||
        enteredAmount > 999999999;

    if (_titleController.text.trim().isEmpty ||
        amountIsInvalid ||
        _selectedDate == null) {
      _showDialog();
      return;
    }

    final expense = Expense(
      title: _titleController.text.trim(),
      amount: enteredAmount.toDouble(),
      date: _selectedDate!,
      category: _selectedCategory,
    );

    try {
      await createExpense(expense);

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
    }
  }

  Widget _buildTitleAmountInputs(double width) {
    return width >= 600
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    label: Text('Titulo'),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    CustomLengthTextInputFormatter(9),
                  ],
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    label: Text('Cantidad'),
                  ),
                ),
              ),
            ],
          )
        : Column(
            children: [
              TextField(
                controller: _titleController,
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Titulo'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CustomLengthTextInputFormatter(9),
                ],
                decoration: const InputDecoration(
                  prefixText: '\$ ',
                  label: Text('Cantidad'),
                ),
              ),
            ],
          );
  }

  Widget _buildCategoryAndDatePicker(double width) {
    return width >= 600
        ? Row(
            children: [
              DropdownButton<Category>(
                value: _selectedCategory,
                items: Category.values
                    .map((category) => DropdownMenuItem<Category>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(categoryIcons[category]),
                              const SizedBox(width: 8),
                              Text(category.name.toUpperCase()),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Seleccione fecha'
                          : formatter.format(_selectedDate!),
                    ),
                    IconButton(
                      onPressed: _presentDatePicker,
                      icon: const Icon(Icons.calendar_month),
                    ),
                  ],
                ),
              ),
            ],
          )
        : Column(
            children: [
              Row(
                children: [
                  DropdownButton<Category>(
                    value: _selectedCategory,
                    items: Category.values
                        .map((category) => DropdownMenuItem<Category>(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(categoryIcons[category]),
                                  const SizedBox(width: 8),
                                  Text(category.name.toUpperCase()),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'Seleccione fecha'
                              : formatter.format(_selectedDate!),
                        ),
                        IconButton(
                          onPressed: _presentDatePicker,
                          icon: const Icon(Icons.calendar_month),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _submitExpenseData,
            child: const Text('Guardar Gasto'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
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
          final width = constraints.maxWidth;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 24, 16, keyboardSpace + 16),
            child: Column(
              children: [
                _buildTitleAmountInputs(width),
                const SizedBox(height: 24),
                _buildCategoryAndDatePicker(width),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }
}
