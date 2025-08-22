import 'package:app_wallet/library/main_library.dart';

class DateSelector extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate == null 
                  ? 'Seleccione fecha' 
                  : formatter.format(selectedDate!),
              style: TextStyle(
                fontSize: 16,
                color: selectedDate == null 
                    ? Colors.grey.shade600 
                    : Colors.black,
                fontWeight: selectedDate == null 
                    ? FontWeight.normal 
                    : FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.calendar_month,
              color: AwColors.appBarColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
