import 'package:app_wallet/library_section/main_library.dart';

class DetailExpenseContent extends StatelessWidget {
  final Expense expense;
  const DetailExpenseContent({required this.expense, super.key});

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
          // Título
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: AwText.bold(expense.title.capitalize(), size: AwSize.s26),
          ),
          // Categoría (ícono + nombre)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(WalletCategoryHelper.getCategoryIcon(expense.category.displayName),
                    size: 18, color: WalletCategoryHelper.getCategoryColor(expense.category.displayName)),
                const SizedBox(width: 8),
                Expanded(
                  child: AwText(text: _getCategoryName(expense.category), size: AwSize.s18),
                ),
              ],
            ),
          ),

          // Subcategoría (ícono opcional + nombre)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                if (expense.subcategoryId != null)
                  Icon(WalletCategoryHelper.getCategoryIcon(expense.subcategoryId!),
                      size: 18, color: WalletCategoryHelper.getCategoryColor(expense.category.displayName)),
                if (expense.subcategoryId != null) const SizedBox(width: 8),
                Expanded(
                  child: AwText(
                    text: _getSubcategoryName(expense.subcategoryId) ?? 'Sin subcategoría',
                    size: AwSize.s18,
                  ),
                ),
              ],
            ),
          ),

          // Fecha
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: AwText(
                text: expense.formattedDate,
                size: AwSize.s18,
                textAlign: TextAlign.end,
              ),
            ),
          ),

          // Monto
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: AwText(
                color: AwColors.boldBlack,
                text: formatNumber(expense.amount),
                size: AwSize.s24,
                textAlign: TextAlign.end,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
