import 'package:app_wallet/library/main_library.dart';
import 'package:app_wallet/models/currency.dart' as currency_model;

class CurrencySelector extends StatelessWidget {
  final currency_model.Currency selectedCurrency;
  final VoidCallback onTap;

  const CurrencySelector({
    super.key,
    required this.selectedCurrency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: AwColors.greyLight,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Center(
                child: AwText.bold(
                  selectedCurrency.code,
                  color: AwColors.black,
                  size: AwSize.s14,
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
