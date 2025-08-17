import 'package:app_wallet/library/main_library.dart';

class DetailExpenseContent extends StatelessWidget {
  final Expense expense;
  const DetailExpenseContent({required this.expense, super.key});

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AwText.bold(title, size: AwSize.s16),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return '\$${formatter.format(value)}';
  }

  String _getCategoryName(Category category) {
    return category.toString().split('.').last.capitalize();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Título:', expense.title.capitalize()),
          _buildDetailRow('Categoría:', _getCategoryName(expense.category)),
          _buildDetailRow('Monto:', formatNumber(expense.amount)),
        ],
      ),
    );
  }
}
