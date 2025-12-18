import 'package:app_wallet/library_section/main_library.dart';

class IngresosAmountField extends StatelessWidget {
  final TextEditingController controller;
  final bool showMaxError;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onAttemptOverLimit;

  const IngresosAmountField({
    Key? key,
    required this.controller,
    required this.showMaxError,
    this.onChanged,
    this.onAttemptOverLimit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AwText.bold('Ingreso mensual', size: AwSize.s14),
        AwSpacing.s6,
        CustomTextField(
          controller: controller,
          label: 'Ingrese monto en CLP',
          keyboardType: TextInputType.number,
          inputFormatters: [
            MaxAmountFormatter(
              maxDigits: MaxAmountFormatter.kEightDigits,
              maxAmount: MaxAmountFormatter.kEightDigitsMaxAmount,
              onAttemptOverLimit: onAttemptOverLimit ?? () {},
            ),
            CLPTextInputFormatter(),
          ],
          textSize: 16,
          onChanged: onChanged,
        ),
        if (showMaxError)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: AwText.normal('Tope máximo: 8 dígitos (99.999.999)',
                color: AwColors.red, size: AwSize.s14),
          ),
      ],
    );
  }
}
