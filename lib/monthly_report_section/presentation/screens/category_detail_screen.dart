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

    IconData _iconForSubId(String? subId) {
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

    String _nameForSubId(String? subId) {
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

    return Scaffold(
      backgroundColor: AwColors.greyLight,
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
        color: Theme.of(context).colorScheme.background,
        child: expenses.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: AwSize.s50, color: Theme.of(context).colorScheme.primary),
                    AwSpacing.m,
                    Text(
                      'No hay gastos asociados a esta categoría durante este mes.',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final e = expenses[index];
                  final subName = _nameForSubId(e.subcategoryId);
                  final subIcon = _iconForSubId(e.subcategoryId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: TicketCard(
                      boxShadowAll: true,
                      roundTopCorners: true,
                      topCornerRadius: 10,
                      compactNotches: true,
                      elevation: 4,
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: Icon(
                          subIcon,
                          size: AwSize.s30,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        title: Text(
                          e.title,
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        subtitle: Text(
                          subName,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatNumber(e.amount),
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            AwSpacing.xs,
                            Text(e.formattedDate, style: Theme.of(context).textTheme.bodySmall),
                            AwSpacing.xs,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
