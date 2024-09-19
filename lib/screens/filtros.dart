import 'package:flutter/material.dart';
import 'package:app_wallet/models/expense.dart';
import 'package:app_wallet/screens/expenses.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  final Map<Category, bool> _filters = {
    Category.comida: false,
    Category.viajes: false,
    Category.ocio: false,
    Category.trabajo: false,
    Category.categoria: false,
  };

  void _saveFilters() {
  Navigator.of(context).pop(_filters); // Guarda los filtros y regresa a la pantalla anterior
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Filtros'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop(); // Regresa a la pantalla anterior
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: _saveFilters, // Guarda los filtros y regresa a la pantalla de gastos
        ),
      ],
    ),
    body: Column(
      children: Category.values.map((category) {
        return SwitchListTile(
          value: _filters[category] ?? false,
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
          activeColor: Theme.of(context).colorScheme.tertiary,
          contentPadding: const EdgeInsets.only(left: 34, right: 22),
        );
      }).toList(),
    ),
  );
}
}