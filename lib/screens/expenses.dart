import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_wallet/models/expense.dart'; // Importa tu modelo de Expense
import 'package:app_wallet/services_bd/firebase_Service.dart'; // Importa la función getGastos
import 'package:app_wallet/widgets/chart/chart.dart'; // Importa el widget del gráfico
import 'package:app_wallet/widgets/expenses_list/expenses_list.dart'; // Importa el widget que lista los gastos
import 'package:app_wallet/widgets/main_drawer.dart'; // Importa el widget del drawer
import 'package:app_wallet/widgets/new_expense.dart'; // Importa el widget para añadir un nuevo gasto
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa para usar Timestamp

class Expenses extends StatefulWidget {
  final Map<Category, bool>? filters; // Recibe los filtros como argumento

  const Expenses({super.key, this.filters}); // Constructor actualizado

  @override
  State<Expenses> createState() {
    return _ExpensesState();
  }
}

class _ExpensesState extends State<Expenses> {
  final List<Expense> _registeredExpenses = [];

  @override
  void initState() {
    super.initState();
    _loadGastosFromFirebase(); // Cargar los datos cuando se inicializa el estado
  }

  // Función para obtener los datos de Firebase
  Future<void> _loadGastosFromFirebase() async {
    List gastosFromFirebase = await getGastos(); // Llamada a tu función para obtener gastos de Firebase

    setState(() {
      _registeredExpenses.clear(); // Limpiar la lista antes de agregar nuevos gastos
      for (var gasto in gastosFromFirebase) {
        Timestamp timestamp = gasto['fecha'];
        DateTime fecha = timestamp.toDate(); // Convertir Timestamp a DateTime

        _registeredExpenses.add(
          Expense(
            title: gasto['name'],
            amount: gasto['cantidad'].toDouble(),
            date: fecha,
            category: _mapCategory(gasto['tipo']),
          ),
        );
      }
    });
  }

  // Función para mapear el tipo de gasto a la categoría
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
      default:
        return Category.categoria;
    }
  }

  // CRUD CREATE: función para guardar un gasto en Firebase
  Future<void> createExpense(Expense expense) async {
    await db.collection('gastos').add({
      'name': expense.title,
      'fecha': Timestamp.fromDate(expense.date),
      'cantidad': expense.amount,
      'tipo': expense.category.toString().split('.').last,
    });
  }

  // Función para abrir el modal de añadir gasto
  void _openAddExpenseOverlay() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (ctx) => NewExpense(onAddExpense: _addExpense),
    );
  }

  // Función para añadir un gasto a la lista y a Firebase
  void _addExpense(Expense expense) {
    setState(() {
      _registeredExpenses.add(expense);
    });

    createExpense(expense).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar gasto: $error')),
      );
    });
  }

  // Función para eliminar un gasto de la lista
  void _removeExpense(Expense expense) async {
    final expenseIndex = _registeredExpenses.indexOf(expense);
    setState(() {
      _registeredExpenses.remove(expense);
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
              _registeredExpenses.insert(expenseIndex, expense);
            });
          },
        ),
      ),
    );
  }

  // Función para manejar la navegación del Drawer
  void _selectScreen(String identifier) {
    Navigator.of(context).pop(); // Cierra el Drawer al seleccionar una opción

    if (identifier == 'filtros') {
      Navigator.of(context).pushNamed('/filtros').then((filters) {
        if (filters != null && filters is Map<Category, bool>) {
          setState(() {
            _applyFilters(filters as Map<Category, bool>); // Aplicar filtros al regresar
          });
        }
      });
    } else if (identifier == 'consejos') {
      Navigator.of(context).pushReplacementNamed('/blank');
    }
  }

  // Aplicar filtros a los gastos
  void _applyFilters(Map<Category, bool> filters) {
  setState(() {
    _registeredExpenses.retainWhere((expense) {
      if (filters[Category.comida] == true && expense.category == Category.comida) return true;
      if (filters[Category.viajes] == true && expense.category == Category.viajes) return true;
      if (filters[Category.ocio] == true && expense.category == Category.ocio) return true;
      if (filters[Category.trabajo] == true && expense.category == Category.trabajo) return true;
      if (filters[Category.categoria] == true && expense.category == Category.categoria) return true;
      return false;
    });
  });
}

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Contenido principal de la lista de gastos
    Widget mainContent = const Center(
      child: Text('No se encontraron gastos. ¡Empieza a agregar algunos!'),
    );

    if (_registeredExpenses.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _registeredExpenses,
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
      drawer: MainDrawer(onSelectScreen: _selectScreen),
      body: width < 600
          ? Column(
              children: [
                Chart(expenses: _registeredExpenses),
                Expanded(
                  child: mainContent,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Chart(expenses: _registeredExpenses),
                ),
                Expanded(
                  child: mainContent,
                ),
              ],
            ),
    );
  }
}
