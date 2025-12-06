import 'package:app_wallet/library_section/main_library.dart';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:app_wallet/ftu_section/ftu_income_helper.dart';
import 'package:app_wallet/ftu_section/ftu_add_helper.dart';
import 'package:app_wallet/ftu_section/ftu_navigation_helper.dart';

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key});

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  StreamSubscription<User?>? _authSub;
  bool _localLoaderActive = false;
  final GlobalKey _editIconKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _statisticsButtonKey = GlobalKey();
  final GlobalKey _informesButtonKey = GlobalKey();
  final GlobalKey _miWalletButtonKey = GlobalKey();

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
            final popupCtx = Navigator.of(context, rootNavigator: true).overlay?.context ?? context;
            WidgetsBinding.instance.addPostFrameCallback((__) {
              try {
                WalletPopup.showNotificationSuccess(
                  context: popupCtx,
                  title: args['title']?.toString() ?? 'Operación completada',
                );
              } catch (_) {}
            });
          }
        }
      } catch (_) {}

      try {
        final provController = context.read<WalletExpensesController>();
        try {
          final container = riverpod.ProviderScope.containerOf(context, listen: false);

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
                  riverpod.ProviderScope.containerOf(context, listen: false).read(globalLoaderProvider.notifier).state =
                      false;
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
          final shouldShowLocal = provController.isLoadingExpenses || provController.filteredExpenses.isEmpty;
          if (shouldShowLocal) {
            setState(() => _localLoaderActive = true);
            try {
              riverpod.ProviderScope.containerOf(context, listen: false).read(globalLoaderProvider.notifier).state =
                  false;
            } catch (_) {}
          }
        } catch (_) {}

        provController.loadExpensesSmart().then((_) {
          try {
            final container = riverpod.ProviderScope.containerOf(context, listen: false);
            container.read(ingresosProvider.notifier).init();
          } catch (_) {}
        });
      } catch (_) {}
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        FTUIncomeHelper.maybeShowFirstTimeIncome(context, _editIconKey);
      } catch (_) {}
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map && args['continueFTUAfterIngresosAdd'] == true) {
          FTUAddHelper.maybeShowAddFTU(context, _fabKey);
        }
      } catch (_) {}
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map && args['continueFTUToStatistics'] == true) {
          final controller = context.read<WalletExpensesController>();
          FTUNavigationHelper.showStatisticsFTU(context, _statisticsButtonKey, controller.allExpenses);
        }
      } catch (_) {}
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map && args['highlightInformesButton'] == true) {
          final controller = context.read<WalletExpensesController>();
          FTUNavigationHelper.showInformesFTU(context, _informesButtonKey, controller.allExpenses);
        }
      } catch (_) {}
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map && args['highlightMiWalletButton'] == true) {
          FTUNavigationHelper.showMiWalletFTU(context, _miWalletButtonKey);
        }
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
    WalletNavigationService.handleBottomNavigation(context, index, controller.allExpenses);
  }

  Future<void> _openAddExpenseOverlay() async {
    final expense = await WalletNavigationService.openAddExpenseOverlay(context);
    if (expense != null) {
      final conn = await Connectivity().checkConnectivity();
      final hasConnection = conn != ConnectivityResult.none;
      final controller = context.read<WalletExpensesController>();
      bool success = false;
      try {
        try {
          riverpod.ProviderScope.containerOf(context, listen: false).read(globalLoaderProvider.notifier).state = true;
        } catch (_) {}

        await controller.addExpense(expense, hasConnection: hasConnection);
        success = true;
      } catch (e) {
        try {
          final popupCtx = Navigator.of(context, rootNavigator: true).overlay?.context ?? context;
          WalletPopup.showNotificationError(
            context: popupCtx,
            title: 'Error al crear gasto.',
          );
        } catch (_) {}
      } finally {
        try {
          riverpod.ProviderScope.containerOf(context, listen: false).read(globalLoaderProvider.notifier).state = false;
        } catch (_) {}
      }

      if (success) {
        try {
          final popupCtx = Navigator.of(context, rootNavigator: true).overlay?.context ?? context;
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
      onAddExpense: () async {
        await _openAddExpenseOverlay();
      },
      onAddRecurrent: () async {
        await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const RecurrentCreatePage()));
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
        key: _fabKey,
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
            statisticsButtonKey: _statisticsButtonKey,
            informesButtonKey: _informesButtonKey,
            miWalletButtonKey: _miWalletButtonKey,
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
              await controller.removeExpense(expense, hasConnection: hasConnection);
            },
          )
        : const EmptyState();

    if (width < 600) {
      return Column(
        children: [
          HomeIncomeCard(controller: controller, isWide: false, editIconKey: _editIconKey),
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
                child: HomeIncomeCard(controller: controller, isWide: true, editIconKey: _editIconKey),
              ),
            ],
          ),
        ),
        Expanded(child: mainContent),
        AwSpacing.w60,
      ],
    );
  }

  Widget _buildMonthButtons(BuildContext context, WalletExpensesController controller) {
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
        WalletPopup.showNotificationWarningOrange(context: context, message: 'No hay meses disponibles para filtrar');
      }
      return;
    }

    final selected = await showMonthSelector(context, available);
    if (selected != null) {
      controller.setMonthFilter(selected);
    }
  }
}
