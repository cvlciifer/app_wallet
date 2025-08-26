import 'package:app_wallet/library/main_library.dart';

class WalletHomeAppbar extends StatelessWidget implements PreferredSizeWidget {
  const WalletHomeAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const AwText.bold('Admin Wallet', color: AwColors.white,),
      actions: [
        IconButton(
          icon: const Icon(Icons.question_answer),
          onPressed: () async {
            await ConsejoProvider.mostrarConsejoDialog(context);
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}