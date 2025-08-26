import 'package:app_wallet/library/main_library.dart';
import 'package:app_wallet/models/currency.dart' as currency_model;

class CurrencyPickerDialog extends StatelessWidget {
  final currency_model.Currency selectedCurrency;
  final Function(currency_model.Currency) onCurrencySelected;

  const CurrencyPickerDialog({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencySelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const AwText(
        text: 'Seleccionar Moneda',
        color: AwColors.boldBlack,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: currency_model.Currency.values.length,
          itemBuilder: (context, index) {
            final currency = currency_model.Currency.values[index];
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selectedCurrency == currency ? AwColors.appBarColor.withOpacity(0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: AwText.bold(
                    currency.symbol,
                    size: AwSize.s18,
                    color: selectedCurrency == currency ? AwColors.appBarColor : Colors.grey.shade600,
                  ),
                ),
              ),
              title: AwText.bold(
                currency.code,
                color: selectedCurrency == currency ? AwColors.appBarColor : Colors.black,
              ),
              subtitle: AwText(
                text: currency.name,
                color: AwColors.black,
                size: AwSize.s12,
              ),
              trailing: selectedCurrency == currency ? Icon(Icons.check, color: AwColors.appBarColor) : null,
              onTap: () {
                onCurrencySelected(currency);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
    );
  }
}
