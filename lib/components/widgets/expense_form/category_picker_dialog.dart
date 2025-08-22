import 'package:app_wallet/library/main_library.dart';

class CategoryPickerDialog extends StatelessWidget {
  final Category selectedCategory;
  final Function(Category) onCategorySelected;

  const CategoryPickerDialog({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Categoría'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: Category.values.length,
          itemBuilder: (context, index) {
            final category = Category.values[index];
            return ListTile(
              leading: Icon(
                categoryIcons[category],
                color: selectedCategory == category 
                    ? AwColors.appBarColor 
                    : Colors.grey,
              ),
              title: Text(
                category.name.toUpperCase(),
                style: TextStyle(
                  fontWeight: selectedCategory == category 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  color: selectedCategory == category 
                      ? AwColors.appBarColor 
                      : Colors.black,
                ),
              ),
              trailing: selectedCategory == category 
                  ? Icon(Icons.check, color: AwColors.appBarColor)
                  : null,
              onTap: () {
                onCategorySelected(category);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
    );
  }
}
