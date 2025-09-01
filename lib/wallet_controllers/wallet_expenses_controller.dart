import 'package:app_wallet/library/main_library.dart';


import '../service_db_local/local_crud.dart';
import '../sync_service/sync_service.dart';


import 'package:firebase_auth/firebase_auth.dart';


class WalletExpensesController extends ChangeNotifier {
  final List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  Map<Category, bool> _currentFilters = {
    Category.comida: false,
    Category.viajes: false,
    Category.ocio: false,
    Category.trabajo: false,
    Category.salud: false,
    Category.servicios: false,
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

  Future<void> loadExpensesFromFirebase() async {
    print('loadExpensesFromFirebase llamado');
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
    await loadExpensesFromFirebase();
  }


  Future<void> removeExpense(Expense expense, {required bool hasConnection}) async {
    print('removeExpense llamado con: \\${expense.title}');
    await syncService.deleteExpense(expense.id, hasConnection: hasConnection);
    await loadExpensesFromFirebase();
  }

  void applyFilters(Map<Category, bool> filters) {
    _currentFilters = Map.from(filters);
    _filteredExpenses = _allExpenses.where((expense) {
      if (filters[Category.comida] == true && expense.category == Category.comida) return true;
      if (filters[Category.viajes] == true && expense.category == Category.viajes) return true;
      if (filters[Category.ocio] == true && expense.category == Category.ocio) return true;
      if (filters[Category.trabajo] == true && expense.category == Category.trabajo) return true;
      if (filters[Category.salud] == true && expense.category == Category.salud) return true;
      if (filters[Category.servicios] == true && expense.category == Category.servicios) return true;
      return false;
    }).toList();
    notifyListeners();
  }
}