import 'dart:math' as math;

import 'package:app_wallet/library_section/main_library.dart';

class _HolePainter extends CustomPainter {
  final Rect holeRect;
  final double borderRadius;
  final Color overlayColor;

  _HolePainter({required this.holeRect, this.borderRadius = 8.0, required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, paint);
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius)), clearPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HolePainter old) {
    return old.holeRect != holeRect || old.borderRadius != borderRadius || old.overlayColor != overlayColor;
  }
}

class EstadisticasScreen extends StatefulWidget {
  final List<Expense> expenses;

  const EstadisticasScreen({Key? key, required this.expenses}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _EstadisticasScreenState createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool groupBySubcategory = false;
  bool _initializedFromController = false;
  // PageView controller and current page index for the charts carousel
  late PageController _pageController;
  int _currentChartPage = 0;

  final GlobalKey _categoryToggleKey = GlobalKey();
  final GlobalKey _chartsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentChartPage);

    // Check if we should show FTU
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map && args['showFTUOnStatistics'] == true) {
          _runStatisticsFTU();
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _runStatisticsFTU() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await _showOverlayForKey(_chartsKey,
          title: 'Gráficos',
          message: 'Aquí puedes ver gráficos de tus gastos. Desliza para ver diferentes visualizaciones.');
      await _showOverlayForKey(_categoryToggleKey,
          title: 'Filtrar por categoría/subcategoría',
          message: 'Cambia entre ver gastos por categoría o subcategoría para más detalle.',
          isFinalStep: true);
    } catch (_) {}
  }

  Future<void> _showOverlayForKey(GlobalKey key,
      {required String title, required String message, bool isFinalStep = false}) async {
    try {
      final ctx = key.currentContext;
      if (ctx == null) return;

      try {
        await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.3);
      } catch (_) {}

      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;
      final targetPos = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;

      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'statistics_ftu',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, a1, a2) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HolePainter(
                      holeRect: Rect.fromLTWH(
                        targetPos.dx - 8,
                        targetPos.dy - 8,
                        targetSize.width + 16,
                        targetSize.height + 16,
                      ),
                      borderRadius: 8.0,
                      overlayColor: Colors.black.withOpacity(0.45),
                    ),
                  ),
                ),
                Positioned(
                  left: (() {
                    final screenW = MediaQuery.of(context).size.width;
                    final popupW = math.min(320, screenW - 32);
                    return (screenW - popupW) / 2;
                  })(),
                  top: (() {
                    final screenH = MediaQuery.of(context).size.height;
                    const popupApproxH = 140.0;
                    final preferAbove = targetPos.dy - popupApproxH - 12;
                    if (preferAbove >= 16) return preferAbove;
                    final preferBelow = targetPos.dy + targetSize.height + 12;
                    final maxTop = screenH - popupApproxH;
                    return preferBelow > maxTop ? maxTop : preferBelow;
                  })(),
                  child: Container(
                    width: math.min(320, MediaQuery.of(context).size.width - 32),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AwText.bold(title, size: AwSize.s14),
                        AwSpacing.s6,
                        AwText.normal(message, size: AwSize.s12, color: AwColors.modalGrey),
                        AwSpacing.s10,
                        Row(
                          children: [
                            Expanded(
                              child: WalletButton.primaryButton(
                                buttonText: isFinalStep ? 'Continuar' : 'Entendido',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  if (isFinalStep) {
                                    // Navigate to home and highlight Informes button
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/home-page',
                                      (r) => false,
                                      arguments: {'highlightInformesButton': true},
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {}
  }

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return '\$${formatter.format(value)}';
  }

  List<Map<String, dynamic>> _getFilteredData(List<Expense> expenses) {
    final filteredExpenses = expenses.where((expense) {
      final expenseDate = expense.date;
      return expenseDate.month == selectedMonth && expenseDate.year == selectedYear;
    }).toList();

    if (!groupBySubcategory) {
      final walletExpenseBuckets = Category.values.map((category) {
        return WalletExpenseBucket.forCategory(filteredExpenses, category);
      }).toList();

      return walletExpenseBuckets.where((bucket) => bucket.totalExpenses > 0).map((bucket) {
        return {
          'label': bucket.category.displayName,
          'amount': bucket.totalExpenses,
          'icon': categoryIcons[bucket.category],
          'color': bucket.category.color,
        };
      }).toList();
    } else {
      final Map<String, double> sums = {};
      double noSubSum = 0.0;
      for (final e in filteredExpenses) {
        if (e.subcategoryId != null && e.subcategoryId!.isNotEmpty) {
          sums[e.subcategoryId!] = (sums[e.subcategoryId!] ?? 0) + e.amount;
        } else {
          noSubSum += e.amount;
        }
      }

      final List<Map<String, dynamic>> result = [];

      for (final entry in sums.entries) {
        Subcategory? found;
        for (final list in subcategoriesByCategory.values) {
          for (final s in list) {
            if (s.id == entry.key) {
              found = s;
              break;
            }
          }
          if (found != null) break;
        }

        result.add({
          'label': found?.name ?? entry.key,
          'amount': entry.value,
          'icon': found?.icon,
          'color': found?.parent.color,
        });
      }

      if (noSubSum > 0) {
        result.add({
          'label': 'Sin subcategoría',
          'amount': noSubSum,
          'icon': Icons.category,
          'color': Colors.grey,
        });
      }
      result.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
      return result;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize from controller once (preserve original behavior)
    if (!_initializedFromController) {
      try {
        final controller = context.read<WalletExpensesController>();
        final mf = controller.monthFilter;
        if (mf != null) {
          selectedMonth = mf.month;
          selectedYear = mf.year;
        }
      } catch (_) {}
      _initializedFromController = true;
    }

    // Ensure expenses reflect either provided list or controller data
    final expenses =
        widget.expenses.isNotEmpty ? widget.expenses : (context.read<WalletExpensesController>().allExpenses);

    // Available years/months
    final availableYears = expenses.map((e) => e.date.year).toSet().toList();
    if (!availableYears.contains(selectedYear) && availableYears.isNotEmpty) {
      selectedYear = availableYears.first;
    }

    final availableMonths =
        expenses.where((e) => e.date.year == selectedYear).map((e) => e.date.month).toSet().toList();
    availableMonths.sort();
    if (!availableMonths.contains(selectedMonth) && availableMonths.isNotEmpty) {
      selectedMonth = availableMonths.first;
    }

    final data = _getFilteredData(expenses);
    final filteredExpensesList =
        expenses.where((e) => e.date.month == selectedMonth && e.date.year == selectedYear).toList();
    final totalAmount = data.fold(0.0, (sum, item) => sum + (item['amount'] as double));

    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold(
          'Estadística Mensual',
          size: AwSize.s18,
          color: AwColors.white,
        ),
        automaticallyImplyLeading: true,
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final mq = MediaQuery.of(ctx);
          final needsScroll = mq.textScaleFactor > 1.15 || constraints.maxHeight < 620;

          final headerRow = Container(
            key: _categoryToggleKey,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          if (groupBySubcategory) setState(() => groupBySubcategory = false);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Categoria',
                          style: TextStyle(
                            color: groupBySubcategory ? AwColors.black : AwColors.appBarColor,
                            fontSize: AwSize.s16,
                          ),
                        ),
                      ),
                      Container(height: 2, color: groupBySubcategory ? Colors.transparent : AwColors.appBarColor),
                    ],
                  ),
                ),
                AwSpacing.w16,
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          if (!groupBySubcategory) setState(() => groupBySubcategory = true);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Subcategoria',
                          style: TextStyle(
                            color: groupBySubcategory ? AwColors.appBarColor : AwColors.black,
                            fontSize: AwSize.s16,
                          ),
                        ),
                      ),
                      Container(height: 2, color: groupBySubcategory ? AwColors.appBarColor : Colors.transparent),
                    ],
                  ),
                ),
              ],
            ),
          );

          Widget chartsSection() {
            if (data.isEmpty) {
              return const Center(
                child: Column(
                  children: [
                    Image(
                      image: AWImage.ghost,
                      fit: BoxFit.contain,
                      width: 96,
                      height: 96,
                    ),
                    AwText.bold(
                      'No existen gastos registrados durante este mes.',
                      size: AwSize.s18,
                      color: AwColors.black,
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AwText.bold(
                  'Gráficos',
                  size: AwSize.s18,
                  color: AwColors.boldBlack,
                ),
                AwSpacing.s,
                Container(
                  key: _chartsKey,
                  height: AwSize.s300,
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (idx) => setState(() => _currentChartPage = idx),
                          children: [
                            WalletPieChart(data: data),
                            Chart(expenses: filteredExpensesList),
                          ],
                        ),
                      ),
                      AwSpacing.s,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(2, (i) {
                          final bool active = _currentChartPage == i;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: active ? 14 : 10,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active ? AwColors.appBarColor : AwColors.grey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          Widget categoryListSection() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AwSpacing.s,
                WalletCategoryList(data: data, formatNumber: formatNumber),
              ],
            );
          }

          if (!needsScroll) {
            // Non-scrolling layout — use Expanded for charts and list
            return Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AwSpacing.s,
                  Material(
                    elevation: 12,
                    color: AwColors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: AwColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headerRow,
                          WalletMonthYearSelector(
                            selectedMonth: selectedMonth,
                            selectedYear: selectedYear,
                            onMonthChanged: (month) => setState(() => selectedMonth = month),
                            onYearChanged: (year) => setState(() => selectedYear = year),
                            availableMonths: availableMonths,
                            availableYears: availableYears,
                            totalAmount: totalAmount,
                            formatNumber: formatNumber,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AwSpacing.s,
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                      child: data.isEmpty
                          ? chartsSection()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                chartsSection(),
                                AwSpacing.s,
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: categoryListSection(),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Scrolling fallback layout — avoid Expanded inside scrollable parents
          return SingleChildScrollView(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AwSpacing.s,
                  Material(
                    elevation: 12,
                    color: AwColors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: AwColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headerRow,
                          WalletMonthYearSelector(
                            selectedMonth: selectedMonth,
                            selectedYear: selectedYear,
                            onMonthChanged: (month) => setState(() => selectedMonth = month),
                            onYearChanged: (year) => setState(() => selectedYear = year),
                            availableMonths: availableMonths,
                            availableYears: availableYears,
                            totalAmount: totalAmount,
                            formatNumber: formatNumber,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AwSpacing.s,
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: data.isEmpty
                        ? chartsSection()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              chartsSection(),
                              AwSpacing.s,
                              categoryListSection(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
