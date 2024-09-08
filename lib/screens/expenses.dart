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
    List gastosFromFirebase =
        await getGastos(); // Llamada a tu función para obtener gastos de Firebase

    setState(() {
      _registeredExpenses
          .clear(); // Limpiar la lista antes de agregar nuevos gastos
      for (var gasto in gastosFromFirebase) {
        // Si 'fecha' es un Timestamp, lo convertimos a DateTime
        Timestamp timestamp = gasto['fecha'];
        DateTime fecha = timestamp.toDate(); // Convertir Timestamp a DateTime

        _registeredExpenses.add(
          Expense(
            title: gasto['name'], // 'name' es el campo de la base de datos
            amount:
                gasto['cantidad'].toDouble(), // Asegúrate de convertir a double
            date: fecha, // Usamos el objeto DateTime convertido
            category:
                _mapCategory(gasto['tipo']), // Mapea el tipo a tu categoría
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
      default:
        return Category.comida; // Si tienes una categoría por defecto
    }
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

  // Función para añadir un gasto a la lista
  void _addExpense(Expense expense) {
    setState(() {
      _registeredExpenses.add(expense);
    });
  }

  // Función para eliminar un gasto de la lista
  void _removeExpense(Expense expense) {
    final expenseIndex = _registeredExpenses.indexOf(expense);
    setState(() {
      _registeredExpenses.remove(expense);
    });

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

    if (identifier == 'gastos') {
      Navigator.of(context).pushReplacementNamed('/blank');
    } else if (identifier == 'consejos') {
      Navigator.of(context).pushReplacementNamed('/blank');
    }
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
