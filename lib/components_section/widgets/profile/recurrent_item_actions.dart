import 'package:app_wallet/library_section/main_library.dart';

class RecurrentItemActions {
  static Future<String?> show(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TicketCard(
              roundTopCorners: true,
              topCornerRadius: 12,
              compactNotches: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading:
                        const Icon(Icons.edit, color: AwColors.appBarColor),
                    title: const AwText.bold('Editar desde este mes'),
                    onTap: () => Navigator.of(ctx).pop('edit'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.redAccent),
                    title: const AwText.bold('Borrar desde este mes'),
                    onTap: () => Navigator.of(ctx).pop('delete'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: const AwText.bold('Borrar solo este mes'),
                    onTap: () => Navigator.of(ctx).pop('delete_single'),
                  ),
                  const Divider(height: 1),
                  AwSpacing.s,
                  WalletButton.textButton(
                    buttonText: 'Cancelar',
                    onPressed: () => Navigator.of(ctx).pop(null),
                    alignment: MainAxisAlignment.center,
                    colorText: AwColors.blue,
                  ),
                  AwSpacing.s,
                ],
              ),
            ),
          ),
        );
      },
    );

    return choice;
  }
}
