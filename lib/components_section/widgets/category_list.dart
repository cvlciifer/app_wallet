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
    final total = data.fold(0.0, (sum, item) => sum + (item['amount'] as double));

    return Column(
      children: data.map((item) {
        final label = item['label'] as String;
        final amount = item['amount'] as double;
        final percentage = total > 0 ? (amount / total) * 100 : 0.0;
        final IconData? iconData = item['icon'] as IconData?;
        final Color? color = item['color'] as Color?;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(
                iconData ?? WalletCategoryHelper.getCategoryIcon(label),
                size: 25,
                color: color ?? WalletCategoryHelper.getCategoryColor(label),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: AwText(
                  text: label,
                  size: AwSize.s16,
                  maxLines: null,
                  textOverflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 80),
                child: AwText(
                  text: formatNumber(amount),
                  size: AwSize.s16,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 56),
                child: AwText(
                  text: '${percentage.toStringAsFixed(1)}%',
                  size: AwSize.s16,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
