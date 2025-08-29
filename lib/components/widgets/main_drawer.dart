import 'package:app_wallet/library/main_library.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    super.key,
    required this.onSelectScreen,
    required this.expenses,
  });

  final void Function(String identifier) onSelectScreen;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wallet,
                  size: AwSize.s48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                AwSpacing.s18,
                const AwText(
                  text: 'ADMIN WALLET',
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.tune,
              size: 26,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            title: const AwText(
              text: 'Filtros',
              size: AwSize.s24,
            ),
            onTap: () {
              onSelectScreen('filtros');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.bar_chart,
              size: 26,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            title: const AwText(
              text: 'Estadisticas',
              size: AwSize.s24,
            ),
            onTap: () {
              onSelectScreen('estadisticas');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => EstadisticasScreen(
                      expenses: expenses), // Pasar la lista de gastos
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.description,
              size: 26,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            title: const AwText(
              text: 'Informe Mensual',
              size: AwSize.s24,
            ),
            onTap: () {
              onSelectScreen('informe_mensual');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => InformeMensualScreen(
                    expenses: expenses,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.question_answer,
              size: 26,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            title: const AwText(
              text: 'Obtener Consejo',
              size: AwSize.s24,
            ),
            onTap: () async {
              Navigator.of(context).pop();
              await ConsejoProvider.mostrarConsejoDialog(context);
            },
          ),
          const Spacer(),
          ListTile(
            leading: Icon(
              Icons.logout,
              size: 26,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            title: const AwText(
              text: 'Cerrar sesión',
              size: AwSize.s24,
            ),
            onTap: () {
              LogOutDialog.showLogOutDialog(context);
            },
          ),
        ],
      ),
    );
  }
}
