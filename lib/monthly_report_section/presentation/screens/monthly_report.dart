import 'package:app_wallet/library_section/main_library.dart';
import 'dart:math' as math;

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

class InformeMensualScreen extends StatefulWidget {
  final List<Expense> expenses;

  const InformeMensualScreen({Key? key, required this.expenses}) : super(key: key);

  @override
  _InformeMensualScreenState createState() => _InformeMensualScreenState();
}

class _InformeMensualScreenState extends State<InformeMensualScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool _initializedFromController = false;
  final GlobalKey _totalCardKey = GlobalKey();
  final GlobalKey _categoryListKey = GlobalKey();
  bool _ftuShown = false;

  @override
  void initState() {
    super.initState();
    _initializeSelectedMonthYear();
    // Mostrar FTU después de que se construya la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_ftuShown) {
        _showInformesFTU();
        _ftuShown = true;
      }
    });
  }

  @override
  void didUpdateWidget(covariant InformeMensualScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses != widget.expenses) {
      _initializeSelectedMonthYear();
    }
  }

  void _initializeSelectedMonthYear() {
    final expenses =
        widget.expenses.isNotEmpty ? widget.expenses : (context.read<WalletExpensesController>().allExpenses);
    final years = expenses.map((e) => e.date.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    if (years.isNotEmpty) {
      selectedYear = years.first;
    }
    final months = expenses.where((e) => e.date.year == selectedYear).map((e) => e.date.month).toSet().toList();
    months.sort();
    if (months.isNotEmpty) {
      selectedMonth = months.first;
    }
  }

  List<int> getAvailableYears() {
    final controller = Provider.of<WalletExpensesController>(context, listen: false);
    final source = widget.expenses.isNotEmpty ? widget.expenses : controller.allExpenses;
    final years = source.map((e) => e.date.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List<int> getAvailableMonthsForYear(int year) {
    final controller = Provider.of<WalletExpensesController>(context, listen: false);
    final source = widget.expenses.isNotEmpty ? widget.expenses : controller.allExpenses;
    final months = source.where((e) => e.date.year == year).map((e) => e.date.month).toSet().toList();
    months.sort();
    return months;
  }

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0', 'es');
    return '\$${formatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    // Listen to controller so reports refresh when local data changes (offline-friendly)
    if (!_initializedFromController) {
      try {
        final controller = Provider.of<WalletExpensesController>(context, listen: false);
        final mf = controller.monthFilter;
        if (mf != null) {
          selectedMonth = mf.month;
          selectedYear = mf.year;
        }
      } catch (_) {}
      _initializedFromController = true;
    }

    final controller = Provider.of<WalletExpensesController>(context);
    final sourceExpenses = widget.expenses.isNotEmpty ? widget.expenses : controller.allExpenses;
    final filteredExpenses = sourceExpenses.where((expense) {
      return expense.date.month == selectedMonth && expense.date.year == selectedYear;
    }).toList();

    final double totalExpenses = filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);
    final expenseBuckets = Category.values.map((category) {
      return WalletExpenseBucket.forCategory(filteredExpenses, category);
    }).toList();

    // Ordenar: primero categorías con gastos (totalExpenses > 0),
    // luego las que no tienen gastos. Dentro de cada grupo ordenamos
    // por total descendente para mostrar las categorías más relevantes arriba.
    expenseBuckets.sort((a, b) {
      final aHas = a.totalExpenses > 0;
      final bHas = b.totalExpenses > 0;
      if (aHas && !bHas) return -1;
      if (!aHas && bHas) return 1;
      return b.totalExpenses.compareTo(a.totalExpenses);
    });

    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold(
          'Informe Mensual',
          size: AwSize.s18,
          color: AwColors.white,
        ),
        automaticallyImplyLeading: true,
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
        child: Column(
          children: [
            // Floating card at the top
            Material(
              key: _totalCardKey,
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
                    AwText.bold(
                      'Total de Gastos: ${formatNumber(totalExpenses)}',
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    AwSpacing.s12,
                    Text(
                      'Selecciona Año y Mes para Filtrar:',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AwSpacing.s,
                    Builder(builder: (context) {
                      final availableYears = getAvailableYears();
                      if (!availableYears.contains(selectedYear) && availableYears.isNotEmpty) {
                        selectedYear = availableYears.first;
                      }
                      final availableMonths = getAvailableMonthsForYear(selectedYear);
                      if (!availableMonths.contains(selectedMonth) && availableMonths.isNotEmpty) {
                        selectedMonth = availableMonths.first;
                      }

                      return WalletMonthYearSelector(
                        selectedMonth: selectedMonth,
                        selectedYear: selectedYear,
                        onMonthChanged: (m) => setState(() => selectedMonth = m),
                        onYearChanged: (y) => setState(() {
                          selectedYear = y;
                          final availableMonths = getAvailableMonthsForYear(y);
                          if (availableMonths.isNotEmpty) {
                            selectedMonth = availableMonths.first;
                          } else {
                            selectedMonth = 1;
                          }
                        }),
                        availableMonths: availableMonths,
                        availableYears: availableYears,
                        totalAmount: totalExpenses,
                        showTotal: false,
                        formatNumber: (d) => formatNumber(d),
                      );
                    }),
                  ],
                ),
              ),
            ),

            AwSpacing.m,

            // List below the card
            Expanded(
              child: ListView.builder(
                key: _categoryListKey,
                padding: EdgeInsets.zero,
                itemCount: expenseBuckets.length,
                itemBuilder: (context, index) {
                  final bucket = expenseBuckets[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SettingsCard(
                        title: bucket.category.displayName,
                        icon: categoryIcons[bucket.category] ?? Icons.category,
                        iconColor: bucket.category.color,
                        subtitle: 'Total: ${formatNumber(bucket.totalExpenses)}',
                        onTap: () {
                          final categoryExpenses = filteredExpenses.where((expense) {
                            return expense.category == bucket.category;
                          }).toList();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => CategoryDetailScreen(
                                category: bucket.category,
                                expenses: categoryExpenses,
                              ),
                            ),
                          );
                        },
                      ),
                      AwSpacing.s6,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInformesFTU() async {
    try {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));

      // Paso 1: Destacar la card de total de gastos
      await _showOverlayForKey(
        _totalCardKey,
        title: 'Filtros y Total de Gastos',
        message:
            'Aquí puedes ver el total de tus gastos y seleccionar el año y mes para filtrar. Los filtros te permiten ver gastos de diferentes períodos.',
        continueText: 'Continuar',
      );

      // Paso 2: Destacar la lista de categorías
      await _showOverlayForKey(
        _categoryListKey,
        title: 'Categorías y Subcategorías',
        message:
            'Estas son tus categorías de gastos. Al presionar una categoría, verás los gastos organizados por subcategorías con sus totales.',
        continueText: 'Continuar',
        isFinalStep: true,
      );

      // Navegar al home con highlight de MiWallet
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home-page',
          (r) => false,
          arguments: {'highlightMiWalletButton': true},
        );
      }

      // Navegar al home con highlight de MiWallet
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home-page',
          (r) => false,
          arguments: {'highlightMiWalletButton': true},
        );
      }
    } catch (_) {}
  }

  Future<void> _showOverlayForKey(
    GlobalKey key, {
    required String title,
    required String message,
    String continueText = 'Continuar',
    bool isFinalStep = false,
  }) async {
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
        barrierLabel: 'informes_ftu',
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
                      borderRadius: 12,
                      overlayColor: AwColors.black.withOpacity(0.45),
                    ),
                  ),
                ),
                Positioned(
                  left: targetPos.dx - 8,
                  top: targetPos.dy - 8,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: targetSize.width + 16,
                      height: targetSize.height + 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AwColors.appBarColor, width: 3),
                      ),
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
                    const popupApproxH = 160.0;
                    final preferAbove = targetPos.dy - popupApproxH - 12;
                    if (preferAbove >= 16) return preferAbove;
                    final preferBelow = targetPos.dy + targetSize.height + 12;
                    final screenH = MediaQuery.of(context).size.height;
                    if (preferBelow + popupApproxH <= screenH - 16) return preferBelow;
                    return 16.0;
                  })(),
                  child: Container(
                    width: math.min(320, MediaQuery.of(context).size.width - 32),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AwColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AwColors.black.withOpacity(0.18), blurRadius: 8)],
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
                                buttonText: continueText,
                                onPressed: () {
                                  Navigator.of(context).pop();
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
}
