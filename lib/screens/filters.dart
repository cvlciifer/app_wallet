import 'package:app_wallet/library/main_library.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late Map<Category, bool> _filters;
  int _currentBottomNavIndex = 0; // Filtros está en el índice 0

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

  void _handleBottomNavTap(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });
    
    switch (index) {
      case 0: // Filtros (ya estamos aquí)
        break;
      case 1: // Estadísticas
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => EstadisticasScreen(
              expenses: [], // Necesitarás pasar los expenses desde donde sea apropiado
            ),
          ),
        );
        break;
      case 2: // Informes
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => InformeMensualScreen(
              expenses: [], // Necesitarás pasar los expenses desde donde sea apropiado
            ),
          ),
        );
        break;
      case 3: // MiWallet
        // Navigator.of(context).pushNamed('/mi-wallet');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WalletAppBar(
        title: const AwText.bold('Filtros', color: AwColors.white,),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
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
      bottomNavigationBar: WalletBottomAppBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _handleBottomNavTap,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción para agregar nuevo gasto
          Navigator.of(context).pushNamed('/add-expense');
        },
        backgroundColor: AwColors.appBarColor,
        child: const Icon(Icons.add, color: AwColors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}