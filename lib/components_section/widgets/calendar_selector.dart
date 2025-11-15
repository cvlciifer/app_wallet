import 'package:app_wallet/library_section/main_library.dart';
import 'package:intl/intl.dart';

class WalletMonthYearSelector extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<int>(
          value: selectedMonth,
          items: availableMonths.map((m) {
            final label = toBeginningOfSentenceCase(
                    DateFormat('MMMM', 'es').format(DateTime(0, m))) ??
                DateFormat('MMMM', 'es').format(DateTime(0, m));
            return DropdownMenuItem(
              value: m,
              child: AwText(text: label),
            );
          }).toList(),
          onChanged: (value) => onMonthChanged(value!),
        ),
        DropdownButton<int>(
          value: selectedYear,
          items: availableYears.map((y) {
            return DropdownMenuItem(
              value: y,
              child: AwText(text: '$y'),
            );
          }).toList(),
          onChanged: (value) => onYearChanged(value!),
        ),
        showTotal
            ? AwText(
                text: 'Total: ${formatNumber(totalAmount)}',
                size: AwSize.s18,
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
