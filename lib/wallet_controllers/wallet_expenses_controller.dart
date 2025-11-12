import 'dart:async';
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

  SyncService syncService = SyncService(localCrud: LocalCrud(), firestore: FirebaseFirestore.instance, userEmail: '');
  StreamSubscription<User?>? _authSub;
  String _currentEmail = '';
  bool isLoadingExpenses = false;
  WalletExpensesController() {
    // Delay async initialization to ensure we can resolve auth state (may be null if
    // Firebase hasn't restored currentUser yet). We perform async init after
    // construction.
    // Defer heavy async work until after the constructor returns and the first
    // event loop turn finishes. This avoids blocking the UI during debug/startup
    // when the controller is created synchronously while the app builds.
    Future.delayed(Duration.zero, () => _asyncInit());
  }

  Future<void> _asyncInit() async {
    // Resolve email from FirebaseAuth or persisted storage
    String email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.isEmpty) {
      try {
        final authSvc = AuthService();
        final saved = await authSvc.getSavedEmail();
        if (saved != null && saved.isNotEmpty) email = saved;
      } catch (_) {}
    }

    log('Email usado para SyncService: $email');
    syncService = SyncService(
      localCrud: LocalCrud(),
      firestore: FirebaseFirestore.instance,
      userEmail: email,
    );
    _currentEmail = email;
    syncService.startAutoSync();

    // Listen for auth changes so switching account reloads data immediately.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      final newEmail = user?.email ?? '';
      if (newEmail == _currentEmail) return;
      _currentEmail = newEmail;
      // Recreate syncService for the new user and perform an immediate sync/load.
      try {
        syncService = SyncService(localCrud: LocalCrud(), firestore: FirebaseFirestore.instance, userEmail: newEmail);
        syncService.startAutoSync();
        // Push any local pending for the new context, then initialize DB from Firebase
        await syncService.syncPendingChanges();
        await syncService.initializeLocalDbFromFirebase();
      } catch (e, st) {
        log('Error handling auth change refresh: $e\n$st');
      }
      // Refresh controller's view
      await loadExpensesSmart();
    });

    // Debug: informar el UID resuelto y el estado local al iniciar para ayudar
    // a diagnosticar problemas de persistencia en cold start offline.
    try {
      final resolvedUid = await getUserUid();
      log('WalletExpensesController: UID resuelto al init -> $resolvedUid');
      final users = await DBHelper.instance.getTodosLosUsuarios();
      log('WalletExpensesController: usuarios locales en BD = ${users.length}');
      final pending = await syncService.localCrud.getPendingExpenses();
      log('WalletExpensesController: pending expenses al init = ${pending.length}');
      // Diagnostic: show counts per uid to detect writes under different uid
      try {
        final counts = await syncService.localCrud.getGastosCountByUid();
        log('WalletExpensesController: gastos por uid = $counts');
      } catch (e, st) {
        log('Error obteniendo counts por uid: $e\n$st');
      }
    } catch (e, st) {
      log('Error debug init controller: $e\n$st');
    }

    // Set the month filter to current month on initialization so the home page
    // shows only current-month expenses by default.
    final now = DateTime.now();
    _monthFilter = DateTime(now.year, now.month);

    // Load expenses initially
    await loadExpensesSmart();
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
      log('Hay internet, sincronizando pendientes locales con la nube...');
      // First push local pending changes, then refresh local DB from remote to avoid
      // overwriting pending local operations.
      await syncService.syncPendingChanges();
      log('Sincronización de pendientes finalizada, obteniendo datos remotos...');
      await syncService.initializeLocalDbFromFirebase();
    } else {
      log('Sin internet, mostrando solo base local');
    }

    List<Expense> gastosFromLocal =
        await syncService.localCrud.getAllExpenses();
    log('Gastos obtenidos localmente: ${gastosFromLocal.length}');

    final visibleExpenses = gastosFromLocal
        .where((e) => e.syncStatus != SyncStatus.pendingDelete)
        .toList();
    // Ordenar por fecha descendente: del más reciente al más antiguo
    visibleExpenses.sort((a, b) => b.date.compareTo(a.date));

    _allExpenses.clear();
    _allExpenses.addAll(visibleExpenses);
    _applyCombinedFilters();
    // finished loading
    isLoadingExpenses = false;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _isDisposed = true;
    super.dispose();
  }

  Future<void> addExpense(Expense expense,
      {required bool hasConnection}) async {
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

  Future<void> removeExpense(Expense expense,
      {required bool hasConnection}) async {
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
        if (ed.year != _monthFilter!.year || ed.month != _monthFilter!.month)
          return false;
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
