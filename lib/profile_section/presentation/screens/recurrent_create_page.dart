import 'package:app_wallet/library_section/main_library.dart';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as prov;
import 'package:app_wallet/core/providers/profile/recurrent_create_provider.dart';

class RecurrentCreatePage extends ConsumerStatefulWidget {
  const RecurrentCreatePage({Key? key}) : super(key: key);

  @override
  ConsumerState<RecurrentCreatePage> createState() =>
      _RecurrentCreatePageState();
}

class _RecurrentCreatePageState extends ConsumerState<RecurrentCreatePage> {
  OverlayEntry? _overlayEntry;
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
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
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
    final creating = ref.read(recurrentCreateProvider).isSubmitting;
    final globalLoading = ref.read(globalLoaderProvider);
    if (creating || globalLoading) return;
    final numericValue =
        _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
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

    if (_selectedMonths < 2 || _selectedMonths > 12) {
      WalletPopup.showNotificationWarningOrange(
          context: context, message: 'Seleccione entre 2 y 12 meses');
      return;
    }

    _showOverlay();
    try {
      final success =
          await ref.read(recurrentCreateProvider.notifier).createFromForm(
                title: _titleController.text.trim(),
                amount: enteredAmount.toDouble(),
                dayOfMonth: _selectedDay,
                months: _selectedMonths,
                startMonth: _selectedStartMonth,
                startYear: _selectedStartYear,
                category: _selectedCategory,
                subcategoryId: _selectedSubcategoryId,
              );
      try {
        final controller =
            prov.Provider.of<WalletExpensesController>(context, listen: false);
        await controller.loadExpensesSmart();
      } catch (_) {}
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        WalletPopup.showNotificationError(
            context: context, title: 'Error creando recurrente');
      }
    } catch (e, st) {
      if (kDebugMode) log('Error creando recurrente', error: e, stackTrace: st);
      if (mounted) {
        WalletPopup.showNotificationError(
            context: context, title: 'Error creando recurrente');
      }
    } finally {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(builder: (context) {
      return Positioned.fill(
        child: Material(
          color: Colors.black45,
          child: const Center(child: WalletLoader(color: AwColors.appBarColor)),
        ),
      );
    });
    try {
      Overlay.of(context).insert(_overlayEntry!);
    } catch (_) {}
  }

  void _hideOverlay() {
    try {
      _overlayEntry?.remove();
    } catch (_) {}
    _overlayEntry = null;
  }

  void _showValidationDialog([String? details]) {
    final contentText = details ?? 'Revise los campos';
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const AwText.bold('Entrada no válida',
                    color: AwColors.boldBlack),
                content: AwText(text: contentText),
                actions: [
                  WalletButton.primaryButton(
                      buttonText: 'Cerrar.',
                      onPressed: () => Navigator.pop(ctx))
                ]));
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
            child: AwText.normal(d.toString(),
                color: selected ? AwColors.white : AwColors.boldBlack),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Compute allowed start range: from now -12 months to now +12 months
    final now = DateTime.now();
    final startRange = DateTime(now.year, now.month - 12, 1);
    final endRange = DateTime(now.year, now.month + 12, 1);

    List<int> yearsInRange() {
      final years = <int>{};
      var dt = startRange;
      while (!dt.isAfter(endRange)) {
        years.add(dt.year);
        dt = DateTime(dt.year, dt.month + 1, 1);
      }
      final list = years.toList()..sort();
      return list;
    }

    List<int> monthsForYear(int year) {
      final months = <int>[];
      var dt = startRange;
      while (!dt.isAfter(endRange)) {
        if (dt.year == year) months.add(dt.month);
        dt = DateTime(dt.year, dt.month + 1, 1);
      }
      return months;
    }

    // Ensure selected start year/month are within allowed range
    final allowedYears = yearsInRange();
    if (!allowedYears.contains(_selectedStartYear)) {
      _selectedStartYear = allowedYears.first;
    }
    final allowedMonthsForSelectedYear = monthsForYear(_selectedStartYear);
    if (!allowedMonthsForSelectedYear.contains(_selectedStartMonth)) {
      _selectedStartMonth = allowedMonthsForSelectedYear.first;
    }

    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold(
          'Registro de gastos recurrentes',
          size: AwSize.s18,
          color: AwColors.white,
        ),
        showBackArrow: false,
        barColor: AwColors.appBarColor,
        automaticallyImplyLeading: true,
        actions: const [],
      ),
      body: LayoutBuilder(builder: (ctx, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 24, 16, keyboardSpace + 16),
          child: Column(children: [
            TicketCard(
              notchDepth: 12,
              elevation: 8,
              color: AwColors.white,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AwSpacing.s12,
                    const FormHeader(
                        title: 'Crear gasto recurrente',
                        subtitle:
                            'Un gasto recurrente es aquel que se repite durante un período determinado, como una cuota, una suscripción o un pago mensual. Ingresa la fecha de inicio (día, mes y año) y el número de meses que este gasto se mantendrá.',
                        titleSize: AwSize.s18,
                        titleColor: AwColors.appBarColor),
                    AwSpacing.s12,
                    CustomTextField(
                        controller: _titleController,
                        label: 'Título',
                        maxLength: 50,
                        hideCounter: true,
                        flat: false),
                    AwSpacing.s12,
                    CategoryPicker(
                        controller: _categoryController,
                        selectedCategory: _selectedCategory,
                        selectedSubcategoryId: _selectedSubcategoryId,
                        onSelect: _selectCategory),
                    AwSpacing.m,
                    // Local amount input styled as rounded outline to match IngresosPage
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AwColors.greyLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const AwText.bold('CLP \$'),
                        ),
                        AwSpacing.m,
                        Expanded(
                          flex: 8,
                          child: CustomTextField(
                            controller: _amountController,
                            label: 'Precio',
                            keyboardType: TextInputType.number,
                            inputFormatters:
                                NumberFormatHelper.getAmountFormatters(),
                            onChanged: _handleAmountChange,
                            flat: false,
                          ),
                        ),
                      ],
                    ),
                    AwSpacing.s20,
                    const AwText.bold('Día del mes', color: AwColors.boldBlack),
                    AwSpacing.s,
                    _buildDayGrid(),
                    AwSpacing.m,
                    // Responsive layout: on narrow screens, stack selectors vertically; on wide screens, place in a row.
                    LayoutBuilder(builder: (ctx, constraints) {
                      final isNarrow = constraints.maxWidth < 420;
                      if (isNarrow) {
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AwText.bold('Mes y año de inicio',
                                  color: AwColors.boldBlack),
                              AwSpacing.s,
                              Row(children: [
                                Expanded(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: _selectedStartMonth,
                                    items: allowedMonthsForSelectedYear
                                        .map((m) => DropdownMenuItem(
                                            value: m,
                                            child: Text(_monthNames[m - 1])))
                                        .toList(),
                                    onChanged: (v) => setState(() =>
                                        _selectedStartMonth = v ??
                                            allowedMonthsForSelectedYear.first),
                                  ),
                                ),
                                AwSpacing.s,
                                Expanded(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: _selectedStartYear,
                                    items: allowedYears
                                        .map((y) => DropdownMenuItem(
                                            value: y, child: Text('$y')))
                                        .toList(),
                                    onChanged: (v) => setState(() {
                                      final newYear = v ?? allowedYears.first;
                                      _selectedStartYear = newYear;
                                      final months = monthsForYear(newYear);
                                      _selectedStartMonth =
                                          months.isNotEmpty ? months.first : 1;
                                    }),
                                  ),
                                ),
                              ]),
                              AwSpacing.s12,
                              const AwText.bold('Meses',
                                  color: AwColors.boldBlack),
                              AwSpacing.s,
                              DropdownButton<int>(
                                isExpanded: true,
                                value: _selectedMonths,
                                items: List.generate(11, (i) => i + 2)
                                    .map((m) => DropdownMenuItem(
                                        value: m, child: Text('$m')))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedMonths = v ?? 2),
                              ),
                            ]);
                      }

                      // wide
                      return Row(children: [
                        Expanded(
                            child: Row(children: [
                          const AwText.bold('Mes y año de inicio',
                              color: AwColors.boldBlack),
                          AwSpacing.s12,
                          DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedStartMonth,
                            items: allowedMonthsForSelectedYear
                                .map((m) => DropdownMenuItem(
                                    value: m, child: Text(_monthNames[m - 1])))
                                .toList(),
                            onChanged: (v) => setState(() =>
                                _selectedStartMonth =
                                    v ?? allowedMonthsForSelectedYear.first),
                          ),
                          AwSpacing.s,
                          DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedStartYear,
                            items: allowedYears
                                .map((y) => DropdownMenuItem(
                                    value: y, child: Text('$y')))
                                .toList(),
                            onChanged: (v) => setState(() {
                              final newYear = v ?? allowedYears.first;
                              _selectedStartYear = newYear;
                              final months = monthsForYear(newYear);
                              _selectedStartMonth = months.isNotEmpty
                                  ? months.first
                                  : _selectedStartMonth;
                            }),
                          ),
                        ])),
                        AwSpacing.s12,
                        Expanded(
                            child: Row(children: [
                          const AwText.bold('Meses', color: AwColors.boldBlack),
                          AwSpacing.s12,
                          DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedMonths,
                            items: List.generate(11, (i) => i + 2)
                                .map((m) => DropdownMenuItem(
                                    value: m, child: Text('$m')))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedMonths = v ?? 2),
                          ),
                        ])),
                      ]);
                    }),
                    AwSpacing.s20,
                    WalletButton.primaryButton(
                        buttonText:
                            (ref.watch(recurrentCreateProvider).isSubmitting ||
                                    ref.watch(globalLoaderProvider))
                                ? 'Creando...'
                                : 'Crear recurrente',
                        onPressed:
                            (ref.watch(recurrentCreateProvider).isSubmitting ||
                                    ref.watch(globalLoaderProvider))
                                ? null
                                : _onCreate),
                    AwSpacing.s30,
                  ]),
            ),
            AwSpacing.s40,
          ]),
        );
      }),
    );
  }
}
