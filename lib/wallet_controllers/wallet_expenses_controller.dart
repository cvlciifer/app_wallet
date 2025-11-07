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
  bool isLoadingExpenses = false;

  WalletExpensesController() {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    log('Email usado para SyncService: $email');
    syncService = SyncService(
      localCrud: LocalCrud(),
      firestore: FirebaseFirestore.instance,
      userEmail: email,
    );
    syncService.startAutoSync();
    // Set the month filter to current month on initialization so the home page
    // shows only current-month expenses by default.
    final now = DateTime.now();
    _monthFilter = DateTime(now.year, now.month);
    loadExpensesSmart();
  }

  bool _isDisposed = false;

  List<Expense> get allExpenses => List.unmodifiable(_allExpenses);
  List<Expense> get filteredExpenses => List.unmodifiable(_filteredExpenses);
  Map<Category, bool> get currentFilters => Map.unmodifiable(_currentFilters);
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  DateTime? _monthFilter;
  DateTime? get monthFilter => _monthFilter;

  Future<void> loadExpensesSmart() async {
    isLoadingExpenses = true;
    if (!_isDisposed) notifyListeners();
    print('loadExpensesSmart llamado');
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
    // Ordenar por fecha descendente: del más reciente al más antiguo
    visibleExpenses.sort((a, b) => b.date.compareTo(a.date));

    _allExpenses.clear();
    _allExpenses.addAll(visibleExpenses);
    _applyCombinedFilters();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense, {required bool hasConnection}) async {
    log('addExpense llamado con: ${expense.title}');
    _isLoading = true;
    notifyListeners();
    try {
      await syncService.createExpense(expense, hasConnection: hasConnection);
      if (hasConnection) {
        await syncService.initializeLocalDbFromFirebase();
      }
      await loadExpensesSmart();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeExpense(Expense expense, {required bool hasConnection}) async {
    log('removeExpense llamado con: \\\${expense.title}');
    _isLoading = true;
    notifyListeners();
    try {
      await syncService.deleteExpense(expense.id, hasConnection: hasConnection);
      if (hasConnection) {
        await syncService.initializeLocalDbFromFirebase();
      }
      await loadExpensesSmart();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void applyFilters(Map<Category, bool> filters) {
    _currentFilters = Map.from(filters);
    _applyCombinedFilters();
    notifyListeners();
  }

  void setMonthFilter(DateTime? month) {
    if (month == null) {
      _monthFilter = null;
    } else {
      // normalize to first day of month
      _monthFilter = DateTime(month.year, month.month);
    }
    _applyCombinedFilters();
    notifyListeners();
  }

  void clearMonthFilter() {
    _monthFilter = null;
    _applyCombinedFilters();
    notifyListeners();
  }

  /// Devuelve la lista de meses (como DateTime al primer día de mes) en los que
  /// existen gastos. Si [excludeCurrent] es true, no incluirá el mes actual.
  List<DateTime> getAvailableMonths({bool excludeCurrent = false}) {
    final months = <DateTime>{};
    for (final e in _allExpenses) {
      final m = DateTime(e.date.year, e.date.month);
      months.add(m);
    }
    if (excludeCurrent) {
      final now = DateTime.now();
      months.remove(DateTime(now.year, now.month));
    }
    final list = months.toList();
    list.sort((a, b) => b.compareTo(a));
    return list;
  }

  void _applyCombinedFilters() {
    final hasCategoryFilters = _currentFilters.containsValue(true);
    _filteredExpenses = _allExpenses.where((expense) {
      // month filter
      if (_monthFilter != null) {
        final ed = DateTime(expense.date.year, expense.date.month);
        if (ed.year != _monthFilter!.year || ed.month != _monthFilter!.month) return false;
      }
      // category filters
      if (hasCategoryFilters) {
        return _currentFilters[expense.category] == true;
      }
      return true;
    }).toList();
    _filteredExpenses.sort((a, b) => b.date.compareTo(a.date));
  }
}
