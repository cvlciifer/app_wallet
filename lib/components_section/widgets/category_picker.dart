import 'package:app_wallet/library_section/main_library.dart';

class CategoryPicker extends StatelessWidget {
  final TextEditingController controller;
  final Category selectedCategory;
  final String? selectedSubcategoryId;
  final void Function(Category category, String? subId, String displayName) onSelect;

  const CategoryPicker({
    Key? key,
    required this.controller,
    required this.selectedCategory,
    required this.selectedSubcategoryId,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon = categoryIcons[selectedCategory]!;
    if (selectedSubcategoryId != null) {
      final list = subcategoriesByCategory[selectedCategory] ?? [];
      for (final s in list) {
        if (s.id == selectedSubcategoryId) {
          icon = s.icon;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: Icon(icon, color: selectedCategory.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  hintText: 'Elige categoría',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () => _openCategoryBottomSheet(
                        controller, selectedCategory, selectedSubcategoryId, onSelect, context),
                  ),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AwColors.appBarColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                onTap: () =>
                    _openCategoryBottomSheet(controller, selectedCategory, selectedSubcategoryId, onSelect, context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openCategoryBottomSheet(TextEditingController controller, Category initialCategory, String? initialSubId,
      void Function(Category category, String? subId, String displayName) onSelect, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.70,
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _CategoryBottomSheetContent(
              initialCategory: initialCategory,
              initialSubId: initialSubId,
              onSelect: (c, s, name) {
                onSelect(c, s, name);
                Navigator.of(ctx).pop();
              },
            ),
          ),
        );
      },
    );
  }
}

class _CategoryBottomSheetContent extends StatefulWidget {
  final Category initialCategory;
  final String? initialSubId;
  final void Function(Category, String?, String) onSelect;

  const _CategoryBottomSheetContent(
      {Key? key, required this.initialCategory, required this.initialSubId, required this.onSelect})
      : super(key: key);

  @override
  State<_CategoryBottomSheetContent> createState() => _CategoryBottomSheetContentState();
}

class _CategoryBottomSheetContentState extends State<_CategoryBottomSheetContent> {
  String _search = '';
  late final ScrollController _scrollController;

  bool _matches(String text) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;
    return text.toLowerCase().contains(q);
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8, top: 4),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
          ),
        ),
        Row(
          children: [
            const Expanded(child: AwText.bold('Seleccionar Categoría')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Cerrar',
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          decoration:
              const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar categoría o subcategoría'),
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 6,
            radius: const Radius.circular(8),
            child: ListView(
              controller: _scrollController,
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
                      onTap: () => widget.onSelect(category, null, mainName),
                    ),
                    ...subcats.where((s) => _matches(s.name)).map((s) {
                      return ListTile(
                        leading: Icon(s.icon,
                            color: widget.initialSubId == s.id ? category.color : category.color.withOpacity(0.5)),
                        title: AwText(text: s.name),
                        onTap: () => widget.onSelect(category, s.id, s.name),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
