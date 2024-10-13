import 'package:flutter/material.dart';
import 'package:app_wallet/models/expense.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late Map<Category, bool> _filters;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _filters =
        ModalRoute.of(context)!.settings.arguments as Map<Category, bool>;
  }

  bool _allCategoriesDeselected() {
    return _filters.values.every((isSelected) => !isSelected);
  }

  Map<Category, bool> _getActiveFilters() {
    if (_allCategoriesDeselected()) {
      return {
        for (var category in Category.values) category: true,
      };
    }
    return _filters;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtros'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(_getActiveFilters());
          },
        ),
      ),
      body: Column(
        
        children: Category.values.map((category) {
          return SwitchListTile(
            
            value: _filters[category]!,
            onChanged: (isChecked) {
              setState(() {
                _filters[category] = isChecked;
              });
            },
            title: Text(
              category.name.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
            subtitle: Text(
              'Solo incluye gastos relacionados con ${category.name}.',
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
            secondary: Icon(categoryIcons[category],
                color: Theme.of(context).colorScheme.onBackground),
            activeColor: Theme.of(context).colorScheme.tertiary,
            contentPadding: const EdgeInsets.only(left: 34, right: 22),
          );
        }).toList(),
      ),
    );
  }
}
