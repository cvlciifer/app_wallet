import 'dart:io';
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

class NewExpense extends StatefulWidget {
  const NewExpense({super.key, required this.onAddExpense});

  final void Function(Expense expense) onAddExpense;

  @override
  State<NewExpense> createState() {
    return _NewExpenseState();
  }
}

class _NewExpenseState extends State<NewExpense> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  Category _selectedCategory = Category.ocio;

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

  void _submitExpenseData() {
    final enteredAmount = int.tryParse(_amountController.text.trim());
    final amountIsInvalid = enteredAmount == null ||
        enteredAmount <= 0 ||
        enteredAmount > 999999999; // Cambiado a enteros

    if (_titleController.text.trim().isEmpty ||
        amountIsInvalid ||
        _selectedDate == null) {
      _showDialog();
      return;
    }

    widget.onAddExpense(
      Expense(
        title: _titleController.text.trim(),
        amount: enteredAmount.toDouble(), // Convertir a double si es necesario
        date: _selectedDate!,
        category: _selectedCategory,
      ),
    );

    // Reset fields after submission
    setState(() {
      _titleController.clear();
      _amountController.clear();
      _selectedDate = null;
      _selectedCategory = Category.ocio;
    });

    Navigator.pop(context);
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
                    CustomLengthTextInputFormatter(9), // Máximo 9 cifras
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
                  CustomLengthTextInputFormatter(9), // Máximo 9 cifras
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
                              Icon(categoryIcons[category]), // Icon
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
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submitExpenseData,
          child: const Text('Ingresar'),
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
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final width = constraints.maxWidth;

        return SizedBox(
          height: double.infinity,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
            child: Column(
              children: [
                _buildTitleAmountInputs(width),
                const SizedBox(height: 16),
                _buildCategoryAndDatePicker(width),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ),
          ),
        );
      },
    );
  }
}
