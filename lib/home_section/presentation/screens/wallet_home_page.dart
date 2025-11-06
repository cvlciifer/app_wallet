import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/components_section/widgets/month_action_button.dart';
import 'package:app_wallet/components_section/widgets/month_selector.dart';

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key});

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  void _onBottomNavTap(int index) async {
    final bottomNav = context.read<BottomNavProvider>();
    bottomNav.setIndex(index);
    final controller = context.read<WalletExpensesController>();
    await WalletNavigationService.handleBottomNavigation(context, index, controller.allExpenses);
    bottomNav.reset();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AwColors.greyLight,
      appBar: const WalletHomeAppbar(),
      body: Consumer<WalletExpensesController>(
        builder: (context, controller, child) {
          return Stack(
            children: [
              _buildBody(context, controller),
              if (controller.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AwColors.appBarColor,
        onPressed: _openAddExpenseOverlay,
        tooltip: 'Agregar gasto',
        child: const Icon(Icons.add, color: AwColors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Consumer<BottomNavProvider>(
        builder: (context, bottomNav, child) {
          final selected = bottomNav.selectedIndex;
          return WalletBottomAppBar(
            currentIndex: selected,
            onTap: _onBottomNavTap,
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, WalletExpensesController controller) {
    final width = MediaQuery.of(context).size.width;

    Widget monthButtons = _buildMonthButtons(context, controller);

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
              monthButtons,
              Expanded(child: mainContent),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    monthButtons,
                    Expanded(child: Chart(expenses: controller.filteredExpenses)),
                  ],
                ),
              ),
              Expanded(child: mainContent),
            ],
          );
  }

  Widget _buildMonthButtons(BuildContext context, WalletExpensesController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MonthActionButton(
              label: 'Mes actual',
              onTap: () {
                final now = DateTime.now();
                controller.setMonthFilter(DateTime(now.year, now.month));
              },
            ),
            const SizedBox(width: 8),
            MonthActionButton(
              label: 'Filtrar por mes',
              onTap: () {
                _handleOpenSelector(controller);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleOpenSelector(WalletExpensesController controller) async {
    final available = controller.getAvailableMonths(excludeCurrent: true);
    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No hay meses disponibles para filtrar')));
      }
      return;
    }

    final selected = await showMonthSelector(context, available);
    if (selected != null) {
      controller.setMonthFilter(selected);
    }
  }
}
