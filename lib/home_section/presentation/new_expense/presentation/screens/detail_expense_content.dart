import 'package:app_wallet/library_section/main_library.dart';

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
              child: AwText(
            text: value,
            size: AwSize.s16,
            textAlign: TextAlign.end,
          )),
        ],
      ),
    );
  }

  Widget _buildDetailRowWidget(String title, Widget valueWidget, {IconData? leadingIcon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (leadingIcon != null) Icon(leadingIcon, size: 18, color: iconColor ?? Colors.grey),
              if (leadingIcon != null) const SizedBox(width: 8),
              AwText.bold(title, size: AwSize.s16),
            ],
          ),
          Flexible(child: valueWidget),
        ],
      ),
    );
  }

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return '\$${formatter.format(value)}';
  }

  String _getCategoryName(Category category) {
    return category.displayName;
  }

  String? _getSubcategoryName(String? id) {
    if (id == null) return null;
    for (final entry in subcategoriesByCategory.entries) {
      for (final s in entry.value) {
        if (s.id == id) return s.name;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(' -   Título:', expense.title.capitalize()),
          _buildDetailRowWidget(
            'Categoría:',
            AwText(text: _getCategoryName(expense.category), size: AwSize.s16, textAlign: TextAlign.end),
            leadingIcon: WalletCategoryHelper.getCategoryIcon(expense.category.displayName),
            iconColor: WalletCategoryHelper.getCategoryColor(expense.category.displayName),
          ),
          _buildDetailRowWidget(
            'Subcategoría:',
            AwText(
              text: _getSubcategoryName(expense.subcategoryId) ?? 'Sin subcategoría',
              size: AwSize.s16,
              textAlign: TextAlign.end,
            ),
            leadingIcon:
                expense.subcategoryId != null ? WalletCategoryHelper.getCategoryIcon(expense.subcategoryId!) : null,
            iconColor: WalletCategoryHelper.getCategoryColor(expense.category.displayName),
          ),
          _buildDetailRow(' -   Fecha:', expense.formattedDate),
          _buildDetailRow(' -   Monto:', formatNumber(expense.amount)),
        ],
      ),
    );
  }
}
