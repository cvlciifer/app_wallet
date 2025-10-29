import 'package:app_wallet/library_section/main_library.dart';

class CategoryPickerDialog extends StatefulWidget {
  final Category selectedCategory;
  final String? selectedSubcategoryId;
  final Function(Category, String?) onCategorySelected;

  const CategoryPickerDialog({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.selectedSubcategoryId,
  });

  @override
  State<CategoryPickerDialog> createState() => _CategoryPickerDialogState();
}

class _CategoryPickerDialogState extends State<CategoryPickerDialog> {
  String _search = '';

  bool _matches(String text) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;
    return text.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const AwText(text: 'Seleccionar Categoría'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration:
                  const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar categoría o subcategoría'),
              onChanged: (v) => setState(() => _search = v),
            ),
            AwSpacing.s10,
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: Category.values.map((category) {
                  final mainName = category.displayName;
                  final subcats = subcategoriesByCategory[category] ?? [];
                  final mainMatches = _matches(mainName);
                  final anySubMatches = subcats.any((s) => _matches(s.name));
                  if (!mainMatches && !anySubMatches) return const SizedBox.shrink();

                  return ExpansionTile(
                    leading: Icon(categoryIcons[category], color: category.color),
                    title: AwText.bold(mainName),
                    children: [
                      ListTile(
                        leading: Icon(categoryIcons[category], color: category.color),
                        title: AwText(text: 'Sin subcategoría (usar ${mainName.toLowerCase()})'),
                        onTap: () {
                          widget.onCategorySelected(category, null);
                          Navigator.of(context).pop();
                        },
                      ),
                      ...subcats.where((s) => _matches(s.name)).map((s) {
                        return ListTile(
                          leading: Icon(s.icon,
                              color: widget.selectedSubcategoryId == s.id
                                  ? category.color
                                  : category.color.withOpacity(0.5)),
                          title: AwText(text: s.name),
                          trailing:
                              widget.selectedSubcategoryId == s.id ? Icon(Icons.check, color: category.color) : null,
                          onTap: () {
                            widget.onCategorySelected(category, s.id);
                            Navigator.of(context).pop();
                          },
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
