import 'dart:developer';
import 'dart:async';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/components_section/widgets/profile/month_selector.dart';
import 'package:app_wallet/core/providers/profile/imprevistos_provider.dart';

class IngresosImprevistosPage extends ConsumerStatefulWidget {
  final DateTime? initialMonth;
  final int? initialImprevisto;

  const IngresosImprevistosPage(
      {Key? key, this.initialMonth, this.initialImprevisto})
      : super(key: key);

  @override
  ConsumerState<IngresosImprevistosPage> createState() =>
      _IngresosImprevistosPageState();
}

class _IngresosImprevistosPageState
    extends ConsumerState<IngresosImprevistosPage> {
  final TextEditingController _amountCtrl = TextEditingController();
  int _selectedMonthOffset = 0;
  Timer? _maxErrorTimer;
  bool _showMaxError = false;
  bool _isAmountValid = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMonth != null) {
      final now = DateTime.now();
      final diff = (widget.initialMonth!.year - now.year) * 12 +
          (widget.initialMonth!.month - now.month);
      _selectedMonthOffset = diff.clamp(0, 11);
    }
    if (widget.initialImprevisto != null && widget.initialImprevisto! > 0) {
      final fmt =
          NumberFormat.currency(locale: 'es_CL', symbol: '', decimalDigits: 0);
      _amountCtrl.text = fmt.format(widget.initialImprevisto);
      // initialize validity based on provided initial value
      final digits = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
      final current = int.tryParse(digits) ?? 0;
      _isAmountValid = digits.isNotEmpty &&
          current <= MaxAmountFormatter.kEightDigitsMaxAmount;
    }
    _amountCtrl.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _maxErrorTimer?.cancel();
    _amountCtrl.removeListener(_onAmountChanged);
    _amountCtrl.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final digits = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final current = int.tryParse(digits) ?? 0;
    final valid = digits.isNotEmpty &&
        current <= MaxAmountFormatter.kEightDigitsMaxAmount;
    if (valid != _isAmountValid) {
      if (!mounted) return;
      setState(() {
        _isAmountValid = valid;
      });
    }
  }

  Future<void> _save() async {
    if (!_isAmountValid || _isSaving) return;
    try {
      ref.read(globalLoaderProvider.notifier).state = true;
    } catch (_) {}
    setState(() {
      _isSaving = true;
    });

    final value =
        int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final now = DateTime.now();
    final target = DateTime(now.year, now.month + _selectedMonthOffset, 1);

    bool saved = false;
    try {
      saved = await ref
          .read(imprevistosProvider.notifier)
          .saveImprevisto(target, 0, value);
    } catch (e) {
      log('ingresos_imprevistos._save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error guardando imprevisto')));
      }
    } finally {
      try {
        ref.read(globalLoaderProvider.notifier).state = false;
      } catch (_) {}
      if (mounted) Navigator.of(context).pop(saved);
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = DateTime(now.year, now.month + _selectedMonthOffset, 1);
    return Scaffold(
      appBar: WalletAppBar(
        title: AwText.bold(
          'Ingresos imprevistos',
          color: AwColors.white,
        ),
        automaticallyImplyLeading: true,
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: TicketCard(
          notchDepth: 12,
          elevation: 6,
          color: AwColors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // const AwText.bold('Ingresos imprevistos', size: AwSize.s18, color: AwColors.appBarColor),
                AwSpacing.s6,
                AwText.normal(
                  'Ingresa un monto imprevisto. Este valor se verá reflejado en ${DateFormat('MMMM yyyy', 'es').format(monthLabel)}.',
                  size: AwSize.s14,
                  color: AwColors.modalGrey,
                ),
                AwSpacing.s18,
                const AwText.normal('Mes seleccionado',
                    size: AwSize.s14, color: AwColors.grey),
                AwSpacing.s6,
                MonthSelector(
                  month: monthLabel,
                  canPrev: _selectedMonthOffset > 0,
                  canNext: _selectedMonthOffset < 11,
                  onPrev: () {
                    setState(() {
                      if (_selectedMonthOffset > 0) _selectedMonthOffset--;
                    });
                  },
                  onNext: () {
                    setState(() {
                      if (_selectedMonthOffset < 11) _selectedMonthOffset++;
                    });
                  },
                ),
                AwSpacing.s12,
                const AwText.normal('Valor imprevisto (CLP)',
                    size: AwSize.s14, color: AwColors.grey),
                AwSpacing.s6,
                CustomTextField(
                  controller: _amountCtrl,
                  label: '',
                  hintText: 'p. ej. 50.000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    MaxAmountFormatter(
                      maxDigits: MaxAmountFormatter.kEightDigits,
                      maxAmount: MaxAmountFormatter.kEightDigitsMaxAmount,
                      onAttemptOverLimit: () {
                        if (!mounted) return;
                        setState(() {
                          _showMaxError = true;
                        });
                        _maxErrorTimer?.cancel();
                        _maxErrorTimer = Timer(const Duration(seconds: 2), () {
                          if (mounted) {
                            setState(() {
                              _showMaxError = false;
                            });
                          }
                        });
                      },
                    ),
                    CLPTextInputFormatter(),
                  ],
                  textSize: 16,
                ),
                if (_showMaxError)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: AwText.normal('Tope máximo: 8 dígitos (99.999.999)',
                        color: AwColors.red, size: AwSize.s14),
                  ),
                AwSpacing.s18,
                SizedBox(
                  height: AwSize.s48,
                  child: ElevatedButton(
                    onPressed: _isAmountValid && !_isSaving ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AwColors.appBarColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AwSize.s16),
                      ),
                    ),
                    child: const Center(
                      child: AwText.bold(
                        'Agregar',
                        color: AwColors.white,
                        size: AwSize.s14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
