import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/components_section/widgets/profile/income_preview_tile.dart';
import 'package:app_wallet/profile_section/presentation/screens/ingresos_imprevistos_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:app_wallet/core/providers/profile/ingresos_provider.dart';

class IngresosPage extends ConsumerStatefulWidget {
  const IngresosPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _IngresosPageState createState() => _IngresosPageState();
}

class _IngresosPageState extends ConsumerState<IngresosPage> {
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat _clpFormatter =
      NumberFormat.currency(locale: 'es_CL', symbol: '', decimalDigits: 0);
  bool _showMaxError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(ingresosProvider.notifier).init();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final state = ref.watch(ingresosProvider);
    final ctrl = ref.read(ingresosProvider.notifier);

    return Scaffold(
      appBar: WalletAppBar(
        title: ' ',
        showBackArrow: false,
        barColor: AwColors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AwColors.appBarColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 24, 16, keyboardSpace + 16),
        child: Column(
          children: [
            TicketCard(
              notchDepth: 12,
              elevation: 8,
              color: AwColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AwSpacing.s12,
                  const AwText.bold('Ingresos mensuales',
                      size: AwSize.s18, color: AwColors.appBarColor),
                  AwSpacing.s6,
                  const AwText.normal('Ingresa monto y duración (meses).',
                      size: AwSize.s14, color: AwColors.modalGrey),
                  const SizedBox(height: 12),
                  const AwText.normal('Monto por mes (CLP)',
                      size: AwSize.s14, color: AwColors.black54),
                  AwSpacing.s6,
                  CustomTextField(
                    controller: _amountController,
                    label: '',
                    hintText: 'p. ej. 700.000',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      MaxAmountFormatter(
                        maxDigits: MaxAmountFormatter.kEightDigits,
                        maxAmount: MaxAmountFormatter.kEightDigitsMaxAmount,
                        onAttemptOverLimit: () {
                          setState(() {
                            _showMaxError = true;
                          });
                          Timer(const Duration(seconds: 2), () {
                            if (mounted) {
                              setState(() {
                                _showMaxError = false;
                              });
                            }
                          });
                        },
                      ),
                      CLPTextInputFormatter()
                    ],
                    textAlign: TextAlign.left,
                    textAlignVertical: TextAlignVertical.center,
                    textSize: 16,
                    onChanged: (value) {
                      // update inline error flag based on current numeric value
                      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                      final current = int.tryParse(digits) ?? 0;
                      setState(() {
                        _showMaxError =
                            current >= MaxAmountFormatter.kEightDigitsMaxAmount;
                      });
                    },
                  ),
                  if (_showMaxError)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: AwText.normal(
                          'Tope máximo: 8 dígitos (99.999.999)',
                          color: AwColors.red,
                          size: AwSize.s14),
                    ),
                  AwSpacing.s12,
                  const AwText.normal('Número de meses (1-12)',
                      size: AwSize.s14, color: AwColors.black54),
                  AwSpacing.s6,
                  // ChoiceChip selector
                  SizedBox(
                    height: 48,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(12, (i) {
                          final m = i + 1;
                          final selected = state.months == m;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text('$m'),
                              selected: selected,
                              onSelected: (sel) {
                                if (sel) ctrl.setMonths(m);
                              },
                              selectedColor: AwColors.appBarColor,
                              backgroundColor: Colors.transparent,
                              labelStyle: TextStyle(
                                color: selected
                                    ? AwColors.white
                                    : AwColors.boldBlack,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  AwSpacing.s18,
                  WalletButton.primaryButton(
                    buttonText: 'Guardar',
                    onPressed: state.isSaving
                        ? null
                        : () async {
                            final parsed = int.tryParse(_amountController.text
                                    .replaceAll(RegExp(r'[^0-9]'), '')) ??
                                0;
                            final amount = parsed >
                                    MaxAmountFormatter.kEightDigitsMaxAmount
                                ? MaxAmountFormatter.kEightDigitsMaxAmount
                                : parsed;
                            if (amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Ingrese monto válido')));
                              return;
                            }
                            try {
                              ref.read(globalLoaderProvider.notifier).state =
                                  true;
                            } catch (_) {}
                            try {
                              final success = await ctrl.save(amount);
                              if (!mounted) {
                                try {
                                  ref
                                      .read(globalLoaderProvider.notifier)
                                      .state = false;
                                } catch (_) {}
                                return;
                              }
                              try {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).clearSnackBars();
                              } catch (_) {}
                              if (success) {
                                // ignore: use_build_context_synchronously
                                Navigator.of(context).pop(true);
                              } else {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Error guardando ingresos')));
                              }
                            } finally {
                              try {
                                ref.read(globalLoaderProvider.notifier).state =
                                    false;
                              } catch (_) {}
                            }
                          },
                  ),
                  AwSpacing.s30,
                  const AwText.bold('Previsualización',
                      size: AwSize.s18, color: AwColors.appBarColor),
                  AwSpacing.s6,
                  Column(
                    children: state.previewMonths.map((d) {
                      final fijo = (_amountController.text.isEmpty)
                          ? 0
                          : (int.tryParse(_amountController.text
                                  .replaceAll(RegExp(r'[^0-9]'), '')) ??
                              0);
                      final id =
                          '${d.year}${d.month.toString().padLeft(2, '0')}';
                      final existing = state.localIncomes[id];
                      final imprevisto = existing != null
                          ? (existing['ingreso_imprevisto'] as int? ?? 0)
                          : 0;
                      final total = fijo + imprevisto;

                      final monthLabel = d.month == DateTime.now().month
                          ? 'Mes actual'
                          : DateFormat('MMMM yyyy').format(d);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: IncomePreviewTile(
                          monthLabel: monthLabel,
                          fijoText: _clpFormatter.format(fijo),
                          imprevistoText: _clpFormatter.format(imprevisto),
                          totalText: _clpFormatter.format(total),
                          onTap: () async {
                            final monthDate = DateTime(d.year, d.month, 1);
                            final saved =
                                await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => IngresosImprevistosPage(
                                  initialMonth: monthDate,
                                  initialImprevisto: imprevisto,
                                ),
                              ),
                            );
                            if (saved == true) {
                              await ctrl.loadLocalIncomes();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  AwSpacing.s30,
                ],
              ),
            ),
            AwSpacing.s40,
          ],
        ),
      ),
    );
  }
}
