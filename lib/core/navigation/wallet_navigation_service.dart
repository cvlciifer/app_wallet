import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/monthly_report_section/presentation/screens/monthly_report.dart';

class WalletNavigationService {
  static void handleBottomNavigation(
      BuildContext context, int index, List<Expense> expenses) {
    switch (index) {
      case 0: // Home/Filtros (ya estamos aquí)
        break;
      case 1: // Estadísticas
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => EstadisticasScreen(
              expenses: expenses,
            ),
          ),
        );
        break;
      case 2: // Informes
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => InformeMensualScreen(
              expenses: expenses,
            ),
          ),
        );
        break;
      case 3: // MiWallet
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => const WalletProfilePage(),
          ),
        );
        break;
    }
  }

  static Future<Expense?> openAddExpenseOverlay(BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/new-expense');
    return result is Expense ? result : null;
  }

  static Future<Map<Category, bool>?> openFiltersPage(
      BuildContext context, Map<Category, bool> currentFilters) async {
    final filters = await Navigator.of(context)
        .pushNamed('/filtros', arguments: currentFilters);
    return filters is Map<Category, bool> ? filters : null;
  }
}
