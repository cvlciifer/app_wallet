import 'package:app_wallet/library_section/main_library.dart';

class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const AmountInput({Key? key, required this.controller, this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AwColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const AwText.bold('CLP \$'),
        ),
        AwSpacing.w16,
        Expanded(
          flex: 8,
          child: CustomTextField(
            controller: controller,
            label: 'Precio',
            keyboardType: TextInputType.number,
            inputFormatters: NumberFormatHelper.getAmountFormatters(),
            onChanged: onChanged,
            flat: true,
          ),
        ),
      ],
    );
  }
}
