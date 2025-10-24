import 'package:app_wallet/library_section/main_library.dart';
import 'package:provider/provider.dart';

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key});

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  int _currentBottomIndex = 0;
  late WalletExpensesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WalletExpensesController();
    // Sincroniza con la nube solo una vez al entrar, luego carga local
    _controller.syncService.initializeLocalDbFromFirebase().then((_) {
      // Evitar llamar al controlador si el widget ya fue desmontado.
      if (!mounted) return;
      _controller.loadExpensesSmart();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomIndex = index;
    });
    WalletNavigationService.handleBottomNavigation(
        context, index, _controller.allExpenses);
  }

  void _openAddExpenseOverlay() async {
    final expense =
        await WalletNavigationService.openAddExpenseOverlay(context);
    if (expense != null) {
      // Aquí deberías detectar la conectividad real, por ahora se asume true
      await _controller.addExpense(expense, hasConnection: true);
    }
  }

  void _openFilters() async {
    final filters = await WalletNavigationService.openFiltersPage(
        context, _controller.currentFilters);
    if (filters != null) {
      _controller.applyFilters(filters);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: const WalletHomeAppbar(),
        body: Consumer<WalletExpensesController>(
          builder: (context, controller, child) {
            return _buildBody(context, controller);
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AwColors.appBarColor,
          onPressed: _openAddExpenseOverlay,
          tooltip: 'Agregar gasto',
          child: const Icon(Icons.add, color: AwColors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: WalletBottomAppBar(
          currentIndex: _currentBottomIndex,
          onTap: _onBottomNavTap,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WalletExpensesController controller) {
    final width = MediaQuery.of(context).size.width;

    Widget mainContent = const EmptyState();
    if (controller.filteredExpenses.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: controller.filteredExpenses,
        onRemoveExpense: (expense) async {
          // Aquí deberías detectar la conectividad real, por ahora se asume true
          await controller.removeExpense(expense, hasConnection: true);
        },
      );
    }

    return width < 600
        ? Column(
            children: [
              Chart(expenses: controller.filteredExpenses),
              const AwDivider(),
              WalletFiltersButton(onTap: _openFilters),
              Expanded(child: mainContent),
            ],
          )
        : Row(
            children: [
              Expanded(child: Chart(expenses: controller.filteredExpenses)),
              Expanded(child: mainContent),
            ],
          );
  }
}
