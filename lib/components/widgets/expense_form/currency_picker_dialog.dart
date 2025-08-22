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
      title: const Text('Seleccionar Moneda'),
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
                  color: selectedCurrency == currency 
                      ? AwColors.appBarColor.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    currency.symbol,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: selectedCurrency == currency 
                          ? AwColors.appBarColor
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              title: Text(
                currency.code,
                style: TextStyle(
                  fontWeight: selectedCurrency == currency 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  color: selectedCurrency == currency 
                      ? AwColors.appBarColor 
                      : Colors.black,
                ),
              ),
              subtitle: Text(
                currency.name,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              trailing: selectedCurrency == currency 
                  ? Icon(Icons.check, color: AwColors.appBarColor)
                  : null,
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
