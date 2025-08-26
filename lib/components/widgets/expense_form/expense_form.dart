import 'package:app_wallet/library/main_library.dart';
import 'package:app_wallet/models/currency.dart' as currency_model;

class ExpenseForm extends StatefulWidget {
  final Function(Expense) onSubmit;

  const ExpenseForm({
    super.key,
    required this.onSubmit,
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  Category _selectedCategory = Category.ocio;
  currency_model.Currency _selectedCurrency = currency_model.Currency.clp;

  void _showCategoryPicker() {
    showDialog(
      context: context,
      builder: (context) => CategoryPickerDialog(
        selectedCategory: _selectedCategory,
        onCategorySelected: (category) {
          setState(() {
            _selectedCategory = category;
          });
        },
      ),
    );
  }

  void _showCurrencyPicker() {
    showDialog(
      context: context,
      builder: (context) => CurrencyPickerDialog(
        selectedCurrency: _selectedCurrency,
        onCurrencySelected: (currency) {
          setState(() {
            _selectedCurrency = currency;
            // Reformatear el amount si ya hay texto
            if (_amountController.text.isNotEmpty) {
              final currentValue = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
              _amountController.text = NumberFormatHelper.formatAmount(currentValue, _selectedCurrency);
            }
          });
        },
      ),
    );
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

  void _handleAmountChange(String value) {
    final formatted = NumberFormatHelper.formatAmount(value, _selectedCurrency);
    if (formatted != _amountController.text) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _submitForm() {
    // Extraer solo los números del texto formateado
    final numericValue = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final enteredAmount = int.tryParse(numericValue);
    final amountIsInvalid = enteredAmount == null || enteredAmount <= 0 || enteredAmount > 999999999999;

    if (_titleController.text.trim().isEmpty || amountIsInvalid || _selectedDate == null) {
      _showValidationDialog();
      return;
    }

    final expense = Expense(
      title: _titleController.text.trim(),
      amount: enteredAmount.toDouble(),
      date: _selectedDate!,
      category: _selectedCategory,
    );

    widget.onSubmit(expense);
  }

  void _showValidationDialog() {
    final dialogContent = Platform.isIOS
        ? CupertinoAlertDialog(
            title: const AwText.bold('Entrada no válida', color: AwColors.boldBlack),
            content: const AwText(text: 'Asegúrese de ingresar un título, monto, fecha y categoría válidos.'),
            actions: [
              WalletButton.primaryButton(
                buttonText: 'Cerrar.',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          )
        : AlertDialog(
            title: const AwText.bold('Entrada no válida', color: AwColors.boldBlack),
            content: const AwText(
              text: 'Asegúrese de ingresar un título, monto, fecha y categoría válidos.',
              color: AwColors.black,
            ),
            actions: [
              WalletButton.primaryButton(
                buttonText: 'Cerrar.',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );

    showDialog(context: context, builder: (ctx) => dialogContent);
  }

  Widget _buildCategoryAndTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategorySelector(
          selectedCategory: _selectedCategory,
          onTap: _showCategoryPicker,
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 8,
          child: CustomTextField(
            controller: _titleController,
            label: 'Titulo',
            maxLength: 50,
            hideCounter: true,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyAndAmountRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CurrencySelector(
          selectedCurrency: _selectedCurrency,
          onTap: _showCurrencyPicker,
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 8,
          child: CustomTextField(
            controller: _amountController,
            label: 'Precio',
            keyboardType: TextInputType.number,
            inputFormatters: NumberFormatHelper.getAmountFormatters(),
            onChanged: _handleAmountChange,
            prefixText: '${_selectedCurrency.symbol} ',
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
    return Column(
      children: [
        const AwText.bold(
          'Agrega un nuevo Gasto',
          size: 20,
        ),
        const SizedBox(height: 24),
        _buildCategoryAndTitleRow(),
        const SizedBox(height: 24),
        _buildCurrencyAndAmountRow(),
        const SizedBox(height: 24),
        DateSelector(
          selectedDate: _selectedDate,
          onTap: _presentDatePicker,
        ),
        const SizedBox(height: 32),
        WalletButton.primaryButton(
          buttonText: 'Añadir Gasto',
          onPressed: _submitForm,
        ),
      ],
    );
  }
}
