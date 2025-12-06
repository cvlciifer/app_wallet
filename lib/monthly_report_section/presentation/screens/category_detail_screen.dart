import 'package:app_wallet/library_section/main_library.dart';

class CategoryDetailScreen extends StatelessWidget {
  final Category category;
  final List<Expense> expenses;

  const CategoryDetailScreen({Key? key, required this.category, required this.expenses}) : super(key: key);

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return '\$${formatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final subcats = subcategoriesByCategory[category] ?? [];

    IconData iconForSubId(String? subId) {
      if (subId == null) return categoryIcons[category] ?? Icons.category;
      for (final s in subcats) {
        if (s.id == subId) return s.icon;
      }
      for (final entry in subcategoriesByCategory.entries) {
        for (final s in entry.value) {
          if (s.id == subId) return s.icon;
        }
      }
      return categoryIcons[category] ?? Icons.category;
    }

    String nameForSubId(String? subId) {
      if (subId == null) return 'Sin subcategoría';
      for (final s in subcats) {
        if (s.id == subId) return s.name;
      }
      for (final entry in subcategoriesByCategory.entries) {
        for (final s in entry.value) {
          if (s.id == subId) return s.name;
        }
      }
      return subId;
    }

    // Agrupar gastos por subcategoría
    final Map<String, List<Expense>> expensesBySubcategory = {};
    for (final expense in expenses) {
      final subKey = expense.subcategoryId ?? 'sin_subcategoria';
      expensesBySubcategory.putIfAbsent(subKey, () => []).add(expense);
    }

    // Calcular totales por subcategoría y ordenar
    final subcategoryTotals = <String, double>{};
    for (final entry in expensesBySubcategory.entries) {
      final total = entry.value.fold<double>(0, (sum, exp) => sum + exp.amount);
      subcategoryTotals[entry.key] = total;
    }

    // Ordenar subcategorías por total descendente
    final sortedSubcategoryKeys = subcategoryTotals.keys.toList()
      ..sort((a, b) => subcategoryTotals[b]!.compareTo(subcategoryTotals[a]!));

    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: AppBar(
        title: Text(
          category.displayName,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        // ignore: deprecated_member_use
        color: Theme.of(context).colorScheme.background,
        child: expenses.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Image(
                      image: AWImage.ghost,
                      fit: BoxFit.contain,
                      width: 96,
                      height: 96,
                    ),
                    AwSpacing.m,
                    Text(
                      'No hay gastos asociados a esta categoría durante este mes.',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : SafeArea(
                bottom: true,
                child: ListView.builder(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
                  itemCount: sortedSubcategoryKeys.length,
                  itemBuilder: (context, index) {
                    final subKey = sortedSubcategoryKeys[index];
                    final subExpenses = expensesBySubcategory[subKey]!;
                    final subTotal = subcategoryTotals[subKey]!;
                    final subName = nameForSubId(subKey == 'sin_subcategoria' ? null : subKey);
                    final subIcon = iconForSubId(subKey == 'sin_subcategoria' ? null : subKey);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado de subcategoría
                        Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          color: AwColors.white,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            decoration: BoxDecoration(
                              color: category.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  subIcon,
                                  size: AwSize.s24,
                                  color: category.color,
                                ),
                                AwSpacing.w12,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AwText.bold(
                                        subName,
                                        size: AwSize.s16,
                                        color: AwColors.boldBlack,
                                      ),
                                      AwSpacing.xxs,
                                      AwText.normal(
                                        'Total: ${formatNumber(subTotal)}',
                                        size: AwSize.s14,
                                        color: category.color,
                                      ),
                                    ],
                                  ),
                                ),
                                AwText.bold(
                                  '${subExpenses.length}',
                                  size: AwSize.s18,
                                  color: AwColors.modalGrey,
                                ),
                                AwSpacing.s6,
                                const AwText.normal(
                                  'gastos',
                                  size: AwSize.s12,
                                  color: AwColors.modalGrey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        AwSpacing.s12,
                        // Lista de gastos de esta subcategoría
                        ...subExpenses.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0, left: 8.0, right: 8.0),
                              child: TicketCard(
                                boxShadowAll: true,
                                roundTopCorners: true,
                                topCornerRadius: 10,
                                compactNotches: true,
                                elevation: 2,
                                color: Theme.of(context).colorScheme.surface,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  leading: Icon(
                                    subIcon,
                                    size: AwSize.s26,
                                    color: category.color,
                                  ),
                                  title: Text(
                                    e.title,
                                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                  ),
                                  subtitle: Text(
                                    e.formattedDate,
                                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              // ignore: deprecated_member_use
                                              .withOpacity(0.6),
                                        ),
                                  ),
                                  trailing: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 88),
                                    child: Text(
                                      formatNumber(e.amount),
                                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            )),
                        AwSpacing.m,
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
