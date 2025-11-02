import 'dart:developer';
import 'package:app_wallet/library_section/main_library.dart';
import '../core/data_base_local/local_crud.dart';
import '../core/sync_service/sync_service.dart';

class WalletExpensesController extends ChangeNotifier {
  final List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  Map<Category, bool> _currentFilters = {
    for (var c in Category.values) c: false,
  };

  late final SyncService syncService;

  WalletExpensesController() {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    log('Email usado para SyncService: $email');
    syncService = SyncService(
      localCrud: LocalCrud(),
      firestore: FirebaseFirestore.instance,
      userEmail: email,
    );
    syncService.startAutoSync();
    loadExpensesSmart();
  }

  List<Expense> get allExpenses => List.unmodifiable(_allExpenses);
  List<Expense> get filteredExpenses => List.unmodifiable(_filteredExpenses);
  Map<Category, bool> get currentFilters => Map.unmodifiable(_currentFilters);

  Future<void> loadExpensesSmart() async {
    log('loadExpensesSmart llamado');
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasConnection = connectivityResult != ConnectivityResult.none;

    if (hasConnection) {
      log('Hay internet, sincronizando con la nube...');
      await syncService.initializeLocalDbFromFirebase();
    } else {
      log('Sin internet, mostrando solo base local');
    }

    List<Expense> gastosFromLocal = await syncService.localCrud.getAllExpenses();
    log('Gastos obtenidos localmente: ${gastosFromLocal.length}');

    final visibleExpenses = gastosFromLocal.where((e) => e.syncStatus != SyncStatus.pendingDelete).toList();

    _allExpenses.clear();
    _allExpenses.addAll(visibleExpenses);
    _filteredExpenses = List.from(_allExpenses);
    notifyListeners();
  }

  Future<void> addExpense(Expense expense, {required bool hasConnection}) async {
    log('addExpense llamado con: ${expense.title}');
    await syncService.createExpense(expense, hasConnection: hasConnection);
    if (hasConnection) {
      await syncService.initializeLocalDbFromFirebase();
    }
    await loadExpensesSmart();
  }

  Future<void> removeExpense(Expense expense, {required bool hasConnection}) async {
    log('removeExpense llamado con: \\${expense.title}');
    await syncService.deleteExpense(expense.id, hasConnection: hasConnection);
    if (hasConnection) {
      await syncService.initializeLocalDbFromFirebase();
    }
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
