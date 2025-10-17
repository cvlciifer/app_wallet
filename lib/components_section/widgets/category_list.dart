import 'package:app_wallet/library_section/main_library.dart';

class WalletCategoryList extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String Function(double) formatNumber;

  const WalletCategoryList({
    Key? key,
    required this.data,
    required this.formatNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: data.map((item) {
        final category = item['category'] as String;
        final amount = item['amount'] as double;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(
                WalletCategoryHelper.getCategoryIcon(category),
                size: 20,
                color: WalletCategoryHelper.getCategoryColor(category),
              ),
              const SizedBox(width: 8),
              AwText(
                text: '$category: ${formatNumber(amount)}',
                size: AwSize.s16,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
