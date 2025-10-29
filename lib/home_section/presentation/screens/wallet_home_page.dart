import 'package:app_wallet/library_section/main_library.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key});

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  int _currentBottomIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomIndex = index;
    });
    final controller = context.read<WalletExpensesController>();
    WalletNavigationService.handleBottomNavigation(context, index, controller.allExpenses);
  }

  void _openAddExpenseOverlay() async {
    final expense = await WalletNavigationService.openAddExpenseOverlay(context);
    if (expense != null) {
      final connectivity = await Connectivity().checkConnectivity();
      final hasConnection = connectivity != ConnectivityResult.none;
      final controller = context.read<WalletExpensesController>();
      await controller.addExpense(expense, hasConnection: hasConnection);
    }
  }

  void _openFilters() async {
    final controller = context.read<WalletExpensesController>();
    final filters = await WalletNavigationService.openFiltersPage(context, controller.currentFilters);
    if (filters != null) {
      controller.applyFilters(filters);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AwColors.greyLight,
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
    );
  }

  Widget _buildBody(BuildContext context, WalletExpensesController controller) {
    final width = MediaQuery.of(context).size.width;

    Widget mainContent = const EmptyState();
    if (controller.filteredExpenses.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: controller.filteredExpenses,
        onRemoveExpense: (expense) async {
          final connectivity = await Connectivity().checkConnectivity();
          final hasConnection = connectivity != ConnectivityResult.none;
          await controller.removeExpense(expense, hasConnection: hasConnection);
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
