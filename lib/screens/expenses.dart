import 'package:flutter/material.dart';
import 'package:app_wallet/models/expense.dart';
import 'package:app_wallet/services_bd/firebase_Service.dart';
import 'package:app_wallet/widgets/chart/chart.dart';
import 'package:app_wallet/widgets/expenses_list/expenses_list.dart';
import 'package:app_wallet/widgets/main_drawer.dart';
import 'package:app_wallet/widgets/new_expense.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _loadGastosFromFirebase();
  }

  Future<void> _loadGastosFromFirebase() async {
    List gastosFromFirebase = await getGastos();

    setState(() {
      _allExpenses.clear();
      for (var gasto in gastosFromFirebase) {
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
      _filteredExpenses = List.from(_allExpenses); // Inicializar los gastos filtrados
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
      case 'categoria':
        return Category.salud;  
      default:
        return Category.servicios;  
    }
  }

  Future<void> createExpense(Expense expense) async {
    await db.collection('gastos').add({
      'name': expense.title,
      'fecha': Timestamp.fromDate(expense.date),
      'cantidad': expense.amount,
      'tipo': expense.category.toString().split('.').last,
    });
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
      _filteredExpenses.add(expense); // También agregar a la lista filtrada
    });

    createExpense(expense).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar gasto: $error')),
      );
    });
  }

  void _removeExpense(Expense expense) async {
    final expenseIndex = _filteredExpenses.indexOf(expense);
    setState(() {
      _filteredExpenses.remove(expense);
    });

    await deleteExpense(expense.title, expense.date);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('Gasto eliminado.'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            setState(() {
              _filteredExpenses.insert(expenseIndex, expense);
            });
          },
        ),
      ),
    );
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

    Widget mainContent = const Center(
      child: Text('No se encontraron gastos. ¡Empieza a agregar algunos!'),
    );

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
        expenses: _allExpenses, // Pasa la lista de gastos aquí
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
        onPressed: _openAddExpenseOverlay,
        child: const Icon(Icons.add),
        tooltip: 'Agregar gasto',
      ),
    );
  }
}
