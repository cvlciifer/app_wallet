import 'package:app_wallet/library_section/main_library.dart';

class ExpenseForm extends StatefulWidget {
  final Function(Expense) onSubmit;
  final Expense? initialExpense;

  const ExpenseForm({
    super.key,
    required this.onSubmit,
    this.initialExpense,
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Elige categoría');
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  Category _selectedCategory = Category.comidaBebida;
  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();

    final init = widget.initialExpense;
    if (init != null) {
      _titleController.text = init.title;
      _selectedDate = init.date;
      _selectedCategory = init.category;
      _selectedSubcategoryId = init.subcategoryId;

      // Usar toInt() para evitar que el ".0" de un double introduzca un dígito extra
      _amountController.text =
          NumberFormatHelper.formatAmount(init.amount.toInt().toString());
      _categoryController.text = init.category.toString().split('.').last;
    }
    // Si no hay un gasto inicial, por defecto seleccionar la fecha de hoy
    _selectedDate ??= DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          TicketCard(
            notchDepth: 12,
            elevation: 10,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AwSpacing.s12,
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: AwColors.appBarColor,
                      size: AwSize.s26,
                    ),
                    AwSpacing.w12,
                    Expanded(
                      child: AwText.bold(
                        'Agrega un nuevo gasto',
                        size: AwSize.s20,
                        color: AwColors.appBarColor,
                      ),
                    ),
                  ],
                ),
                AwSpacing.s6,
                const AwText(
                  text:
                      'Registra un gasto. Puedes elegir Título, Categoría, Precio y Fecha.',
                  color: AwColors.blueGrey,
                  size: AwSize.s14,
                  textAlign: TextAlign.left,
                ),
                AwSpacing.xs,
                _buildTitle(),
                AwSpacing.s12,
                CategoryPicker(
                  controller: _categoryController,
                  selectedCategory: _selectedCategory,
                  selectedSubcategoryId: _selectedSubcategoryId,
                  onSelect: _selectCategory,
                ),
                AwSpacing.s24,
                AmountInput(
                    controller: _amountController,
                    onChanged: _handleAmountChange),
                AwSpacing.s24,
                DateSelector(
                  selectedDate: _selectedDate,
                  onTap: _presentDatePicker,
                ),
                AwSpacing.s20,
                WalletButton.primaryButton(
                  buttonText: 'Añadir Gasto',
                  onPressed: _submitForm,
                ),
                AwSpacing.s30,
              ],
            ),
          ),
          AwSpacing.s40,
        ],
      ),
    );
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final lastDate = DateTime(now.year + 1, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (!mounted) return;
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _handleAmountChange(String value) {
    final formatted = NumberFormatHelper.formatAmount(value);
    if (formatted != _amountController.text) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _submitForm() {
    final numericValue =
        _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final enteredAmount = int.tryParse(numericValue);
    final amountIsInvalid = enteredAmount == null ||
        enteredAmount <= 0 ||
        enteredAmount > 999999999999;

    final titleEmpty = _titleController.text.trim().isEmpty;
    final dateEmpty = _selectedDate == null;

    if (titleEmpty || amountIsInvalid || dateEmpty) {
      final missing = <String>[];
      if (titleEmpty) missing.add('Título');
      if (amountIsInvalid) missing.add('Precio válido (> 0)');
      if (dateEmpty) missing.add('Fecha');

      final details = 'Por favor ingrese: ${missing.join(', ')}.';
      _showValidationDialog(details);
      return;
    }

    final expense = Expense(
      title: _titleController.text.trim(),
      amount: enteredAmount.toDouble(),
      date: _selectedDate!,
      category: _selectedCategory,
      subcategoryId: _selectedSubcategoryId,
    );

    widget.onSubmit(expense);
  }

  void _showValidationDialog([String? details]) {
    final contentText =
        details ?? 'Asegúrese de ingresar un título, monto y fecha válidos.';
    final dialogContent = Platform.isIOS
        ? CupertinoAlertDialog(
            title: const AwText.bold('Entrada no válida',
                color: AwColors.boldBlack),
            content: AwText(text: contentText),
            actions: [
              WalletButton.primaryButton(
                buttonText: 'Cerrar.',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          )
        : AlertDialog(
            title: const AwText.bold('Entrada no válida',
                color: AwColors.boldBlack),
            content: AwText(
              text: contentText,
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

  void _selectCategory(Category category, String? subId, String displayName) {
    if (!mounted) return;
    setState(() {
      _selectedCategory = category;
      _selectedSubcategoryId = subId;
      _categoryController.text = displayName;
    });
  }

  Widget _buildTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 8,
          child: CustomTextField(
            controller: _titleController,
            label: 'Título',
            maxLength: 50,
            hideCounter: true,
            flat: true,
          ),
        ),
      ],
    );
  }
}
