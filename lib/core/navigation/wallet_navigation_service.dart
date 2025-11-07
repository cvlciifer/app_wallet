import 'package:app_wallet/library_section/main_library.dart';

class WalletNavigationService {
  static void handleBottomNavigation(
      BuildContext context, int index, List<Expense> expenses) {
    switch (index) {
      case 0:
        return Future.value();
      case 1:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => EstadisticasScreen(
              expenses: expenses,
            ),
          ),
        );
        return;

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
        double totalAmount = expenses.fold(0, (sum, expense) => sum + expense.amount);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => const WalletProfilePage(),
          ),
        );
        return;
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
