import 'package:app_wallet/library_section/main_library.dart';
import 'dart:math' as math;
import 'package:app_wallet/home_section/presentation/screens/two_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:app_wallet/core/providers/profile/ingresos_provider.dart';
import 'package:app_wallet/components_section/widgets/home_income_card.dart';
import 'package:app_wallet/components_section/widgets/month_selector.dart';

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key});

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  StreamSubscription<User?>? _authSub;
  bool _localLoaderActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map && args['showPopup'] == true) {
          final lifecycle = WidgetsBinding.instance.lifecycleState;
          final isResumed = lifecycle == AppLifecycleState.resumed;
          final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
          if (isResumed && isCurrent) {
            final popupCtx =
                Navigator.of(context, rootNavigator: true).overlay?.context ??
                    context;
            WidgetsBinding.instance.addPostFrameCallback((__) {
              try {
                final dynamic msgArg = args['message'];
                Widget? messageWidget;
                if (msgArg != null) {
                  if (msgArg is Widget) {
                    messageWidget = msgArg;
                  } else {
                    messageWidget = AwText.normal(
                      msgArg.toString(),
                      color: AwColors.white,
                      size: AwSize.s14,
                    );
                  }
                }

                WalletPopup.showNotificationSuccess(
                  context: popupCtx,
                  title: args['title']?.toString() ?? 'Operación completada',
                  message: messageWidget,
                );
              } catch (_) {}
            });
          }
        }
      } catch (_) {}

      try {
        final provController = context.read<WalletExpensesController>();
        try {
          final container =
              riverpod.ProviderScope.containerOf(context, listen: false);

          _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
            try {
              container.read(ingresosProvider.notifier).init();
            } catch (_) {}
          });
        } catch (_) {}
        provController.addListener(() {
          try {
            if (provController.isLoadingExpenses) {
              if (!_localLoaderActive) {
                setState(() => _localLoaderActive = true);
                try {
                  riverpod.ProviderScope.containerOf(context, listen: false)
                      .read(globalLoaderProvider.notifier)
                      .state = false;
                } catch (_) {}
              }
            } else {
              if (_localLoaderActive) {
                setState(() => _localLoaderActive = false);
              }
            }
          } catch (_) {}
        });

        try {
          final shouldShowLocal = provController.isLoadingExpenses ||
              provController.filteredExpenses.isEmpty;
          if (shouldShowLocal) {
            setState(() => _localLoaderActive = true);
            try {
              riverpod.ProviderScope.containerOf(context, listen: false)
                  .read(globalLoaderProvider.notifier)
                  .state = false;
            } catch (_) {}
          }
        } catch (_) {}

        provController.loadExpensesSmart().then((_) {
          try {
            final container =
                riverpod.ProviderScope.containerOf(context, listen: false);
            container.read(ingresosProvider.notifier).init();
          } catch (_) {}
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    try {
      _authSub?.cancel();
    } catch (_) {}
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    final controller = context.read<WalletExpensesController>();
    WalletNavigationService.handleBottomNavigation(
        context, index, controller.allExpenses);
  }

  void _openAddExpenseOverlay() async {
    final expense =
        await WalletNavigationService.openAddExpenseOverlay(context);
    if (expense != null) {
      final conn = await Connectivity().checkConnectivity();
      final hasConnection = conn != ConnectivityResult.none;
      final controller = context.read<WalletExpensesController>();
      bool success = false;
      try {
        try {
          riverpod.ProviderScope.containerOf(context, listen: false)
              .read(globalLoaderProvider.notifier)
              .state = true;
        } catch (_) {}

        await controller.addExpense(expense, hasConnection: hasConnection);
        success = true;
      } catch (e) {
        try {
          final popupCtx =
              Navigator.of(context, rootNavigator: true).overlay?.context ??
                  context;
          WalletPopup.showNotificationError(
            context: popupCtx,
            title: 'Error al crear gasto.',
          );
        } catch (_) {}
      } finally {
        try {
          riverpod.ProviderScope.containerOf(context, listen: false)
              .read(globalLoaderProvider.notifier)
              .state = false;
        } catch (_) {}
      }

      if (success) {
        try {
          final popupCtx =
              Navigator.of(context, rootNavigator: true).overlay?.context ??
                  context;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              if (!hasConnection) {
                Future.microtask(() async {
                  await Future.delayed(const Duration(milliseconds: 120));
                  try {
                    WalletPopup.showNotificationSuccess(
                      context: popupCtx,
                      title: 'Gasto creado correctamente.',
                      message: const AwText.normal(
                        'Será sincronizado cuando exista internet',
                        color: AwColors.white,
                        size: AwSize.s14,
                      ),
                      visibleTime: 2,
                      isDismissible: true,
                    );
                  } catch (_) {}
                });
              } else {
                try {
                  WalletPopup.showNotificationSuccess(
                    context: popupCtx,
                    title: 'Gasto creado correctamente.',
                  );
                } catch (_) {}
              }
            } catch (_) {}
          });
        } catch (_) {}
      }
    }
  }

  void _showTwoOptionsDialog() {
    showTwoOptionsDialog(
      context,
      onAddExpense: () {
        _openAddExpenseOverlay();
      },
      onAddRecurrent: () {
        Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const RecurrentCreatePage()));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletHomeAppbar(),
      body: Consumer<WalletExpensesController>(
        builder: (context, controller, child) {
          return Stack(
            children: [
              _buildBody(context, controller),
              if (_localLoaderActive) ...[
                Positioned.fill(
                  child: Container(
                    // ignore: deprecated_member_use
                    color: AwColors.white.withOpacity(0.9),
                    child: const Center(
                      child: SizedBox(
                        height: AwSize.s48,
                        child: WalletLoader(color: AwColors.appBarColor),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AwColors.appBarColor,
        onPressed: _showTwoOptionsDialog,
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

    final monthButtons = _buildMonthButtons(context, controller);

    final Widget mainContent = controller.filteredExpenses.isNotEmpty
        ? ExpensesList(
            expenses: controller.filteredExpenses,
            onRemoveExpense: (expense) async {
              final connectivity = await Connectivity().checkConnectivity();
              final hasConnection = connectivity != ConnectivityResult.none;
              await controller.removeExpense(expense,
                  hasConnection: hasConnection);
            },
          )
        : const EmptyState();

    if (width < 600) {
      return Column(
        children: [
          HomeIncomeCard(controller: controller, isWide: false),
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
              Expanded(
                child: HomeIncomeCard(controller: controller, isWide: true),
              ),
            ],
          ),
        ),
        Expanded(child: mainContent),
        AwSpacing.w60,
      ],
    );
  }

  Widget _buildMonthButtons(
      BuildContext context, WalletExpensesController controller) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = math.min(70.0, screenWidth * 0.08);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
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
            AwSpacing.w12,
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
        WalletPopup.showNotificationWarningOrange(
            context: context, message: 'No hay meses disponibles para filtrar');
      }
      return;
    }

    final selected = await showMonthSelector(context, available);
    if (selected != null) {
      controller.setMonthFilter(selected);
    }
  }
}
