import 'dart:math';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/core/models/recurring_expense.dart';
import 'package:app_wallet/core/sync_service/sync_service.dart';
import 'package:uuid/uuid.dart';

class RecurrentCreatePage extends StatefulWidget {
  const RecurrentCreatePage({Key? key}) : super(key: key);

  @override
  State<RecurrentCreatePage> createState() => _RecurrentCreatePageState();
}

class _RecurrentCreatePageState extends State<RecurrentCreatePage> {
  
  bool _isSubmitting = false;
    final _titleController = TextEditingController();
    final _categoryController = TextEditingController(text: 'Elige categoría');
    final _amountController = TextEditingController();
    Category _selectedCategory = Category.comidaBebida;
    String? _selectedSubcategoryId;
    int _selectedDay = DateTime.now().day;
    int _selectedMonths = 3;
  int _selectedStartMonth = DateTime.now().month;
  int _selectedStartYear = DateTime.now().year;
    final List<String> _monthNames = const [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    @override
    void dispose() {
      _titleController.dispose();
      _categoryController.dispose();
      _amountController.dispose();
      super.dispose();
    }

    void _selectCategory(Category category, String? subId, String displayName) {
      setState(() {
        _selectedCategory = category;
        _selectedSubcategoryId = subId;
        _categoryController.text = displayName;
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

    Future<void> _onCreate() async {
      if (_isSubmitting) return;
      setState(() {
        _isSubmitting = true;
      });
      final numericValue = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
      final enteredAmount = int.tryParse(numericValue);
      final amountIsInvalid = enteredAmount == null || enteredAmount <= 0;
      final titleEmpty = _titleController.text.trim().isEmpty;
      if (titleEmpty || amountIsInvalid) {
        final missing = <String>[];
        if (titleEmpty) missing.add('Título');
        if (amountIsInvalid) missing.add('Precio válido (> 0)');
        final details = 'Por favor ingrese: ${missing.join(', ')}.';
        _showValidationDialog(details);
        return;
      }

      if (_selectedMonths < 1 || _selectedMonths > 12) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione entre 1 y 12 meses')));
        return;
      }

      final recurrenceId = const Uuid().v4();
      final generated = <Expense>[];
      for (var i = 0; i < _selectedMonths; i++) {
        final monthDate = DateTime(_selectedStartYear, _selectedStartMonth + i);
        final lastDay = DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
        final actualDay = min(_selectedDay, lastDay);
        final dt = DateTime(monthDate.year, monthDate.month, actualDay);
        final expenseId = '$recurrenceId-${i + 1}';
        final e = Expense(
          id: expenseId,
          title: _titleController.text.trim(),
            amount: enteredAmount.toDouble(),
          date: dt,
          category: _selectedCategory,
          subcategoryId: _selectedSubcategoryId,
          syncStatus: SyncStatus.pendingCreate,
        );
        generated.add(e);
      }

      final recurring = RecurringExpense(
        id: recurrenceId,
        title: _titleController.text.trim(),
          amount: enteredAmount.toDouble(),
        dayOfMonth: _selectedDay,
        months: _selectedMonths,
        startYear: _selectedStartYear,
        startMonth: _selectedStartMonth,
        category: _selectedCategory,
        subcategoryId: _selectedSubcategoryId,
      );

      try {
        final controller = Provider.of<WalletExpensesController>(context, listen: false);
        await controller.syncService.localCrud.insertRecurring(recurring, generated);
        await controller.loadExpensesSmart();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gasto recurrente creado')));
        Navigator.of(context).pop(true);
      } catch (e, st) {
        if (kDebugMode) debugPrint('Error creando recurrente: $e\n$st');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error creando recurrente')));
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }

    void _showValidationDialog([String? details]) {
      final contentText = details ?? 'Revise los campos';
      showDialog(context: context, builder: (ctx) => AlertDialog(title: const AwText.bold('Entrada no válida', color: AwColors.boldBlack), content: AwText(text: contentText), actions: [WalletButton.primaryButton(buttonText: 'Cerrar.', onPressed: () => Navigator.pop(ctx))]));
    }

    Widget _buildDayGrid() {
      const int maxDay = 31;
      final items = List<int>.generate(maxDay, (i) => i + 1);
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: items.map((d) {
          final selected = d == _selectedDay;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = d),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AwColors.blue : AwColors.greyLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: AwText.normal(d.toString(), color: selected ? AwColors.white : AwColors.boldBlack),
            ),
          );
        }).toList(),
      );
    }

    @override
    Widget build(BuildContext context) {
      final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
      return Scaffold(
        appBar: const WalletAppBar(title: AwText.bold('Gastos Recurrentes', color: AwColors.white), showBackArrow: true),
        body: LayoutBuilder(builder: (ctx, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 24, 16, keyboardSpace + 16),
            child: Column(children: [
              TicketCard(
                notchDepth: 12,
                elevation: 8,
                color: Colors.white,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 12),
                  const FormHeader(title: 'Crear gasto recurrente', subtitle: 'Ingresa título, categoría, monto y selecciona día del mes y duración.'),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _titleController, label: 'Título', maxLength: 50, hideCounter: true, flat: true),
                  const SizedBox(height: 12),
                  CategoryPicker(controller: _categoryController, selectedCategory: _selectedCategory, selectedSubcategoryId: _selectedSubcategoryId, onSelect: _selectCategory),
                  const SizedBox(height: 16),
                  AmountInput(controller: _amountController, onChanged: _handleAmountChange),
                  const SizedBox(height: 20),
                  const AwText.bold('Día del mes', color: AwColors.boldBlack),
                  const SizedBox(height: 8),
                  _buildDayGrid(),
                  const SizedBox(height: 16),
                    // Responsive layout: on narrow screens, stack selectors vertically; on wide screens, place in a row.
                    LayoutBuilder(builder: (ctx, constraints) {
                      final isNarrow = constraints.maxWidth < 420;
                      if (isNarrow) {
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const AwText.bold('Mes y año de inicio', color: AwColors.boldBlack),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: _selectedStartMonth,
                                items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(_monthNames[m - 1]))).toList(),
                                onChanged: (v) => setState(() => _selectedStartMonth = v ?? 1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: _selectedStartYear,
                                items: List.generate(3, (i) => DateTime.now().year + i).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                                onChanged: (v) => setState(() => _selectedStartYear = v ?? DateTime.now().year),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          const AwText.bold('Meses', color: AwColors.boldBlack),
                          const SizedBox(height: 8),
                          DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedMonths,
                            items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text('$m'))).toList(),
                            onChanged: (v) => setState(() => _selectedMonths = v ?? 1),
                          ),
                        ]);
                      }

                      // wide
                      return Row(children: [
                        Expanded(child: Row(children: [
                          const AwText.bold('Mes y año de inicio', color: AwColors.boldBlack),
                          const SizedBox(width: 12),
                          DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedStartMonth,
                            items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(_monthNames[m - 1]))).toList(),
                            onChanged: (v) => setState(() => _selectedStartMonth = v ?? 1),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedStartYear,
                            items: List.generate(3, (i) => DateTime.now().year + i).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                            onChanged: (v) => setState(() => _selectedStartYear = v ?? DateTime.now().year),
                          ),
                        ])),
                        const SizedBox(width: 12),
                        Expanded(child: Row(children: [
                          const AwText.bold('Meses', color: AwColors.boldBlack),
                          const SizedBox(width: 12),
                          DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedMonths,
                            items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text('$m'))).toList(),
                            onChanged: (v) => setState(() => _selectedMonths = v ?? 1),
                          ),
                        ])),
                      ]);
                    }),
                  const SizedBox(height: 20),
                  WalletButton.primaryButton(buttonText: _isSubmitting ? 'Creando...' : 'Crear recurrente', onPressed: _isSubmitting ? null : _onCreate),
                  const SizedBox(height: 30),
                ]),
              ),
              const SizedBox(height: 40),
            ]),
          );
        }),
      );
    }
  }
