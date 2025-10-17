import 'package:app_wallet/library_section/main_library.dart';

class WalletFiltersButton extends StatelessWidget {
  final VoidCallback onTap;

  const WalletFiltersButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list, color: AwColors.appBarColor, size: 20),
              SizedBox(width: 4),
              Text.rich(
                TextSpan(
                  text: "Filtros",
                  style: TextStyle(
                    fontSize: AwSize.s14,
                    fontWeight: FontWeight.bold,
                    color: AwColors.appBarColor,
                    decoration: TextDecoration.underline,
                    decorationColor: AwColors.appBarColor,
                    decorationThickness: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
