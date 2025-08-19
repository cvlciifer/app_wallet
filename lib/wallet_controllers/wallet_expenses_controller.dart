import 'dart:developer';
import 'package:app_wallet/library/main_library.dart';

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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? get userEmail => _auth.currentUser?.email;

  List<Expense> get allExpenses => List.unmodifiable(_allExpenses);
  List<Expense> get filteredExpenses => List.unmodifiable(_filteredExpenses);
  Map<Category, bool> get currentFilters => Map.unmodifiable(_currentFilters);

  Future<void> loadExpensesFromFirebase() async {
    List gastosFromFirebase = await getGastos();

    _allExpenses.clear();
    for (var gasto in gastosFromFirebase) {
      try {
        if (gasto['fecha'] != null &&
            gasto['fecha'] is Timestamp &&
            gasto['name'] != null &&
            gasto['cantidad'] != null &&
            gasto['tipo'] != null) {
          Timestamp timestamp = gasto['fecha'];
          DateTime fecha = timestamp.toDate();
          _allExpenses.add(
            Expense(
              title: gasto['name'],
              amount: gasto['cantidad'].toDouble(),
              date: fecha,
              category: _mapCategory(gasto['tipo']),
            ),
          );
        }
      } catch (e) {
        print('Error al procesar gasto: $e');
      }
    }
    _filteredExpenses = List.from(_allExpenses);
    notifyListeners();
  }

  Category _mapCategory(String tipo) {
    switch (tipo) {
      case 'trabajo':
        return Category.trabajo;
      case 'ocio':
        return Category.ocio;
      case 'comida':
        return Category.comida;
      case 'viajes':
        return Category.viajes;
      case 'salud':
        return Category.salud;
      default:
        return Category.servicios;
    }
  }

  Future<void> createExpense(Expense expense) async {
    if (userEmail != null) {
      await db.collection('usuarios').doc('Gastos').collection(userEmail!).add({
        'name': expense.title,
        'fecha': Timestamp.fromDate(expense.date),
        'cantidad': expense.amount,
        'tipo': expense.category.toString().split('.').last,
      });
    } else {
      log('Error: El email del usuario no está disponible.');
    }
  }

  Future<void> addExpense(Expense expense) async {
    _allExpenses.add(expense);
    _filteredExpenses.add(expense);
    notifyListeners();
    await loadExpensesFromFirebase();
  }

  Future<void> removeExpense(Expense expense) async {
    final expenseIndex = _filteredExpenses.indexOf(expense);

    if (expenseIndex == -1) {
      print('Error: El gasto no se encontró en _filteredExpenses');
      return;
    }

    _filteredExpenses.remove(expense);
    notifyListeners();
    log('Gasto eliminado de la vista: ${expense.title}, ${expense.date}');

    await deleteExpense(expense);
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