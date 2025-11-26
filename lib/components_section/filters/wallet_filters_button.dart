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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_list,
                  color: AwColors.appBarColor, size: 20),
              AwSpacing.xw,
              UnderlinedButton(
                text: 'Filtros',
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
