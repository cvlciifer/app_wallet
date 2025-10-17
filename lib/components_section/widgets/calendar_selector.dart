import 'package:app_wallet/library_section/main_library.dart';

class WalletMonthYearSelector extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final Function(int) onMonthChanged;
  final Function(int) onYearChanged;
  final double totalAmount;
  final String Function(double) formatNumber;

  const WalletMonthYearSelector({
    Key? key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.totalAmount,
    required this.formatNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<int>(
          value: selectedMonth,
          items: List.generate(12, (index) {
            return DropdownMenuItem(
              value: index + 1,
              child: AwText(text: DateFormat('MMMM').format(DateTime(0, index + 1))),
            );
          }),
          onChanged: (value) => onMonthChanged(value!),
        ),
        DropdownButton<int>(
          value: selectedYear,
          items: List.generate(5, (index) {
            int year = DateTime.now().year - index;
            return DropdownMenuItem(
              value: year,
              child: AwText(text: '$year'),
            );
          }),
          onChanged: (value) => onYearChanged(value!),
        ),
        AwText(
          text: 'Total: ${formatNumber(totalAmount)}',
          size: AwSize.s18,
        ),
      ],
    );
  }
}
