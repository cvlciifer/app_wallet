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
      body: expenses.isEmpty
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
                  final subName = nameForSubId(subKey == 'sin_subcategoria' ? null : subKey);
                  final subIcon = iconForSubId(subKey == 'sin_subcategoria' ? null : subKey);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AwSpacing.s12,
                      ...subExpenses.map((e) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TicketCard(
                              boxShadowAll: true,
                              roundTopCorners: true,
                              topCornerRadius: 10,
                              compactNotches: true,
                              elevation: 6,
                              color: AwColors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: Icon(
                                  subIcon,
                                  size: AwSize.s26,
                                  color: category.color,
                                ),
                                title: AwText.bold(
                                  e.title,
                                  size: AwSize.s18,
                                  color: AwColors.boldBlack,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AwText.normal(
                                      e.formattedDate,
                                      size: AwSize.s14,
                                      color: AwColors.grey,
                                    ),
                                    AwText.normal(
                                      subName,
                                      size: AwSize.s14,
                                      color: AwColors.grey,
                                    ),
                                  ],
                                ),
                                trailing: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 88),
                                  child: AwText.bold(
                                    formatNumber(e.amount),
                                    size: AwSize.s22,
                                    color: AwColors.boldBlack,
                                    fontWeight: FontWeight.w800,
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
    );
  }
}
