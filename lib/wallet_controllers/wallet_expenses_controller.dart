import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_wallet/library_section/main_library.dart';

import '../core/data_base_local/local_crud.dart';
import '../core/sync_service/sync_service.dart';

import 'package:firebase_auth/firebase_auth.dart';

class WalletExpensesController extends ChangeNotifier {
  final List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  Map<Category, bool> _currentFilters = {
    for (var c in Category.values) c: false,
  };

  late final SyncService syncService;

  WalletExpensesController() {
    // Inicializa el servicio de sincronización con el email real del usuario autenticado
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    print('Email usado para SyncService: $email');
    syncService = SyncService(
      localCrud: LocalCrud(),
      firestore: FirebaseFirestore.instance,
      userEmail: email,
    );
    syncService.startAutoSync();
  }

  List<Expense> get allExpenses => List.unmodifiable(_allExpenses);
  List<Expense> get filteredExpenses => List.unmodifiable(_filteredExpenses);
  Map<Category, bool> get currentFilters => Map.unmodifiable(_currentFilters);

  /// Carga los gastos desde la nube si hay internet, o desde la base local si no hay conexión
  Future<void> loadExpensesSmart() async {
    print('loadExpensesSmart llamado');
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasConnection = connectivityResult != ConnectivityResult.none;

    if (hasConnection) {
      print('Hay internet, sincronizando con la nube...');
      await syncService.initializeLocalDbFromFirebase();
    } else {
      print('Sin internet, mostrando solo base local');
    }

    List<Expense> gastosFromLocal = await syncService.localCrud.getAllExpenses();
    print('Gastos obtenidos localmente: ${gastosFromLocal.length}');
    _allExpenses.clear();
    _allExpenses.addAll(gastosFromLocal);
    _filteredExpenses = List.from(_allExpenses);
    notifyListeners();
  }

  Future<void> addExpense(Expense expense, {required bool hasConnection}) async {
    print('addExpense llamado con: ${expense.title}');
    await syncService.createExpense(expense, hasConnection: hasConnection);
    // Sincroniza la base local con la nube después de guardar
    await syncService.initializeLocalDbFromFirebase();
    await loadExpensesSmart();
  }

  Future<void> removeExpense(Expense expense, {required bool hasConnection}) async {
    print('removeExpense llamado con: \\${expense.title}');
    await syncService.deleteExpense(expense.id, hasConnection: hasConnection);
    await loadExpensesSmart();
  }

  void applyFilters(Map<Category, bool> filters) {
    _currentFilters = Map.from(filters);
    _filteredExpenses = _allExpenses.where((expense) {
      return filters[expense.category] == true;
    }).toList();
    notifyListeners();
  }
}
