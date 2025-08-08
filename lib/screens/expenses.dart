import 'package:app_wallet/library/main_library.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() {
    return _ExpensesState();
  }
}

class _ExpensesState extends State<Expenses> {
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
  String? userEmail;

  @override
  void initState() {
    super.initState();
    userEmail = _auth.currentUser?.email;
    _loadGastosFromFirebase();
  }

  Future<void> _loadGastosFromFirebase() async {
    List gastosFromFirebase = await getGastos();

    setState(() {
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
    });
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
      print('Error: El email del usuario no está disponible.');
    }
  }

  void _openAddExpenseOverlay() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (ctx) => NewExpense(onAddExpense: _addExpense),
    );
  }

  void _addExpense(Expense expense) {
    setState(() {
      _allExpenses.add(expense);
      _filteredExpenses.add(expense);
    });

    createExpense(expense).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar gasto: $error')),
      );
    });
  }

  void _removeExpense(Expense expense) async {
    final expenseIndex = _filteredExpenses.indexOf(expense);

    if (expenseIndex == -1) {
      print('Error: El gasto no se encontró en _filteredExpenses');
      return;
    }

    // Eliminar el gasto de la vista
    setState(() {
      _filteredExpenses.remove(expense);
    });
    print('Gasto eliminado de la vista: ${expense.title}, ${expense.date}');

    // Llamar a la función deleteExpense con el objeto completo
    await deleteExpense(expense);

    // Recargar los gastos desde Firebase
    await _loadGastosFromFirebase();
  }

  void _selectScreen(String identifier) {
    Navigator.of(context).pop();

    if (identifier == 'filtros') {
      Navigator.of(context)
          .pushNamed('/filtros', arguments: _currentFilters)
          .then((filters) {
        if (filters != null && filters is Map<Category, bool>) {
          setState(() {
            _currentFilters = filters;
            _applyFilters(filters);
          });
        }
      });
    } else if (identifier == 'consejos') {
      Navigator.of(context).pushReplacementNamed('/blank');
    }
  }

  void _applyFilters(Map<Category, bool> filters) {
    setState(() {
      _filteredExpenses = _allExpenses.where((expense) {
        if (filters[Category.comida] == true &&
            expense.category == Category.comida) return true;
        if (filters[Category.viajes] == true &&
            expense.category == Category.viajes) return true;
        if (filters[Category.ocio] == true && expense.category == Category.ocio)
          return true;
        if (filters[Category.trabajo] == true &&
            expense.category == Category.trabajo) return true;
        if (filters[Category.salud] == true &&
            expense.category == Category.salud) return true;
        if (filters[Category.servicios] == true &&
            expense.category == Category.servicios) return true;
        return false;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    Widget mainContent = const EmptyState(); // Usamos el nuevo widget

    if (_filteredExpenses.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _filteredExpenses,
        onRemoveExpense: _removeExpense,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Billetera'),
        actions: [
          IconButton(
            onPressed: _openAddExpenseOverlay,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: MainDrawer(
        onSelectScreen: _selectScreen,
        expenses: _allExpenses,
      ),
      body: width < 600
          ? Column(
              children: [
                Chart(expenses: _filteredExpenses),
                Expanded(child: mainContent),
              ],
            )
          : Row(
              children: [
                Expanded(child: Chart(expenses: _filteredExpenses)),
                Expanded(child: mainContent),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        focusColor: const Color.fromARGB(255, 18, 73, 132),
        onPressed: _openAddExpenseOverlay,
        child: const Icon(Icons.add),
        tooltip: 'Agregar gasto',
      ),
    );
  }
}
