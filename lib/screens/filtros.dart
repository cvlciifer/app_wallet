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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtros'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Volver a la pantalla anterior
          },
        ),
      ),
      body: Column(
        children: Category.values.map((category) {
          return SwitchListTile(
            value: _filters[category]!,
            onChanged: (isChecked) {
              setState(() {
                _filters[category] =
                    isChecked; // Actualizar el estado del filtro
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .pop(_filters); // Devolver los filtros actuales al regresar
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
