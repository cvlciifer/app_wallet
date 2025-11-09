import 'package:app_wallet/library_section/main_library.dart';

class CategorySelector extends StatelessWidget {
  final Category selectedCategory;
  final String? selectedSubcategoryId;
  final VoidCallback onTap;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onTap,
    this.selectedSubcategoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade50,
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  (() {
                    if (selectedSubcategoryId != null) {
                      final list = subcategoriesByCategory[selectedCategory] ?? [];
                      Subcategory? found;
                      for (final s in list) {
                        if (s.id == selectedSubcategoryId) {
                          found = s;
                          break;
                        }
                      }
                      if (found != null) return found.icon;
                    }
                    return categoryIcons[selectedCategory];
                  })(),
                  size: 28,
                  color: selectedCategory.color,
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
