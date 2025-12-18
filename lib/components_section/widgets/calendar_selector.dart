import 'package:app_wallet/library_section/main_library.dart';
import 'package:intl/intl.dart';

class WalletMonthYearSelector extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  final Function(int) onMonthChanged;
  final Function(int) onYearChanged;
  final List<int> availableMonths;
  final List<int> availableYears;
  final double totalAmount;
  final bool showTotal;
  final String Function(double) formatNumber;

  const WalletMonthYearSelector({
    Key? key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.availableMonths,
    required this.availableYears,
    required this.totalAmount,
    required this.formatNumber,
    this.showTotal = true,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _WalletMonthYearSelectorState createState() => _WalletMonthYearSelectorState();
}

class _WalletMonthYearSelectorState extends State<WalletMonthYearSelector> {
  final ScrollController _totalScrollController = ScrollController();
  bool _autoScrolling = false;

  @override
  void dispose() {
    _autoScrolling = false;
    _totalScrollController.dispose();
    super.dispose();
  }

  Future<void> _maybeStartAutoScroll() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    if (!_totalScrollController.hasClients) return;
    final maxExtent = _totalScrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    if (_autoScrolling) return;
    _autoScrolling = true;

    // loop animation: scroll to end, pause, scroll back, pause
    while (_autoScrolling && mounted) {
      try {
        await _totalScrollController.animateTo(
          maxExtent,
          duration: const Duration(seconds: 4),
          curve: Curves.linear,
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (!_autoScrolling || !mounted) break;
        await _totalScrollController.animateTo(
          0,
          duration: const Duration(seconds: 4),
          curve: Curves.linear,
        );
        await Future.delayed(const Duration(milliseconds: 1200));
      } catch (_) {
        break;
      }
    }
    _autoScrolling = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      final showInline = maxW.isFinite && maxW >= 360;

      if (showInline) {
        // inline row: month, year, total (total uses scroll controller)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeStartAutoScroll();
        });

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownButton<int>(
              value: widget.selectedMonth,
              items: widget.availableMonths.map((m) {
                final label = toBeginningOfSentenceCase(DateFormat('MMMM', 'es').format(DateTime(0, m))) ??
                    DateFormat('MMMM', 'es').format(DateTime(0, m));
                return DropdownMenuItem(
                  value: m,
                  child: AwText(text: label),
                );
              }).toList(),
              onChanged: (value) => widget.onMonthChanged(value!),
            ),
            DropdownButton<int>(
              value: widget.selectedYear,
              items: widget.availableYears.map((y) {
                return DropdownMenuItem(
                  value: y,
                  child: AwText(text: '$y'),
                );
              }).toList(),
              onChanged: (value) => widget.onYearChanged(value!),
            ),
            widget.showTotal
                ? Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        controller: _totalScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: AwText(
                            text: 'Total: ${widget.formatNumber(widget.totalAmount)}',
                            size: AwSize.s18,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        );
      }

      // Narrow layout: stack selectors and show total below
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DropdownButton<int>(
                value: widget.selectedMonth,
                items: widget.availableMonths.map((m) {
                  final label = toBeginningOfSentenceCase(DateFormat('MMMM', 'es').format(DateTime(0, m))) ??
                      DateFormat('MMMM', 'es').format(DateTime(0, m));
                  return DropdownMenuItem(
                    value: m,
                    child: AwText(text: label),
                  );
                }).toList(),
                onChanged: (value) => widget.onMonthChanged(value!),
              ),
              AwSpacing.w12,
              DropdownButton<int>(
                value: widget.selectedYear,
                items: widget.availableYears.map((y) {
                  return DropdownMenuItem(
                    value: y,
                    child: AwText(text: '$y'),
                  );
                }).toList(),
                onChanged: (value) => widget.onYearChanged(value!),
              ),
            ],
          ),
          if (widget.showTotal) ...[
            AwSpacing.s,
            Align(
              alignment: Alignment.centerRight,
              child: AwText.bold(
                'Total: ${widget.formatNumber(widget.totalAmount)}',
                size: 20,
                color: AwColors.boldBlack,
                textAlign: TextAlign.right,
              ),
            ),
          ]
        ],
      );
    });
  }
}
