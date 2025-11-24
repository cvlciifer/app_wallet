import 'package:app_wallet/library_section/main_library.dart';

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

  void _handleBottomNavTap(int index) async {
    final bottomNav = context.read<BottomNavProvider>();
    bottomNav.setIndex(index);

    switch (index) {
      case 0:
        break;
      case 1:
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => EstadisticasScreen(
              expenses: [],
            ),
          ),
        );
        bottomNav.reset();
        break;
      case 2: // Informes
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => InformeMensualScreen(
              expenses: [],
            ),
          ),
        );
        bottomNav.reset();
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: WalletAppBar(
        title: const AwText.bold(
          'Filtros',
          color: AwColors.white,
        ),
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
              category.displayName.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
            subtitle: Text(
              'Solo incluye gastos relacionados con ${category.displayName}.',
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
            secondary: Icon(categoryIcons[category], color: category.color),
            activeColor: Theme.of(context).colorScheme.tertiary,
            contentPadding: const EdgeInsets.only(left: 34, right: 22),
          );
        }).toList(),
      ),
      bottomNavigationBar: Consumer<BottomNavProvider>(
        builder: (context, bottomNav, child) {
          return WalletBottomAppBar(
            currentIndex: bottomNav.selectedIndex,
            onTap: _handleBottomNavTap,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/add-expense');
        },
        backgroundColor: AwColors.appBarColor,
        child: const Icon(Icons.add, color: AwColors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
