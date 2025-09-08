import 'package:app_wallet/library/main_library.dart';
import '../../screens/gmail_search_screen.dart';
import '../../screens/bank_emails_screen.dart';

class WalletHomeAppbar extends StatelessWidget implements PreferredSizeWidget {
  const WalletHomeAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Admin Wallet'),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.email),
          tooltip: 'Correos Gmail',
          onSelected: (String value) {
            switch (value) {
              case 'search':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GmailSearchScreen(),
                  ),
                );
                break;
              case 'banks':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BankEmailsScreen(),
                  ),
                );
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'banks',
              child: Row(
                children: [
                  Icon(Icons.account_balance),
                  SizedBox(width: 8),
                  Text('Correos Bancarios'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 8),
                  Text('Buscar por Asunto'),
                ],
              ),
            ),
          ],
        ),
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