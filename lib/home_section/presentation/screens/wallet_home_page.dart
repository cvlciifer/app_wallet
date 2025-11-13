import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:app_wallet/components_section/widgets/month_selector.dart';

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key});

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  // Use the controller provided by Provider (MultiProvider in main)
  bool _initialLoaderHidden = false;

  @override
  void initState() {
    super.initState();
    // Attach to the provided controller after the first frame so context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final provController = context.read<WalletExpensesController>();
        provController.addListener(() {
          try {
            if (!_initialLoaderHidden && !provController.isLoadingExpenses) {
              _initialLoaderHidden = true;
              final ctx = context;
              try {
                riverpod.ProviderScope.containerOf(ctx, listen: false).read(globalLoaderProvider.notifier).state =
                    false;
              } catch (_) {}
            }
          } catch (_) {}
        });

        // Evitar doble inicialización: el controlador ya realiza la carga
        // inicial (incluyendo sincronización cuando hay conexión). Simplemente
        // pedirle que cargue el estado inteligente local/remoto.
        provController.loadExpensesSmart();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    // Do not dispose the provided controller (managed by Provider)
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    // don't keep local index state here; bottom nav state is provided by BottomNavProvider
    final controller = context.read<WalletExpensesController>();
    WalletNavigationService.handleBottomNavigation(context, index, controller.allExpenses);
  }

  void _openAddExpenseOverlay() async {
    final expense = await WalletNavigationService.openAddExpenseOverlay(context);
    if (expense != null) {
      // Detectar conectividad real antes de intentar crear el gasto
      final conn = await Connectivity().checkConnectivity();
      final hasConnection = conn != ConnectivityResult.none;
      final controller = context.read<WalletExpensesController>();
      await controller.addExpense(expense, hasConnection: hasConnection);
    }
  }

  // _openFilters removed - not referenced

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

    if (controller.isLoadingExpenses) {
      return const Center(
        child: SizedBox(
          height: AwSize.s48,
          child: WalletLoader(color: AwColors.appBarColor),
        ),
      );
    }

    final monthButtons = _buildMonthButtons(context, controller);

    final Widget mainContent = controller.filteredExpenses.isNotEmpty
        ? ExpensesList(
            expenses: controller.filteredExpenses,
            onRemoveExpense: (expense) async {
              final connectivity = await Connectivity().checkConnectivity();
              final hasConnection = connectivity != ConnectivityResult.none;
              await controller.removeExpense(expense, hasConnection: hasConnection);
            },
          )
        : const EmptyState();

    if (width < 600) {
      return Column(
        children: [
          Chart(expenses: controller.filteredExpenses),
          monthButtons,
          Expanded(child: mainContent),
        ],
      );
    }

    return Row(
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
        const SizedBox(width: AwSize.s60),
      ],
    );
  }

  Widget _buildMonthButtons(BuildContext context, WalletExpensesController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 4),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WalletButton.filterButton(
              buttonText: 'Mes actual',
              onPressed: () {
                final now = DateTime.now();
                controller.setMonthFilter(DateTime(now.year, now.month));
              },
              selected: controller.monthFilter != null &&
                  controller.monthFilter!.year == DateTime.now().year &&
                  controller.monthFilter!.month == DateTime.now().month,
            ),
            const Spacer(),
            WalletButton.filterButton(
              buttonText: 'Filtrar por mes',
              onPressed: () {
                _handleOpenSelector(controller);
              },
              selected: controller.monthFilter != null &&
                  !(controller.monthFilter!.year == DateTime.now().year &&
                      controller.monthFilter!.month == DateTime.now().month),
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
