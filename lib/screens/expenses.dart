import 'package:flutter/material.dart';

import 'package:app_wallet/widgets/new_expense.dart';
import 'package:app_wallet/widgets/expenses_list/expenses_list.dart';
import 'package:app_wallet/models/expense.dart';
import 'package:app_wallet/widgets/chart/chart.dart';
import 'package:app_wallet/widgets/main_drawer.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() {
    return _ExpensesState();
  }
}

class _ExpensesState extends State<Expenses> {
  final List<Expense> _registeredExpenses = [
    Expense(
      title: 'Flutter Course',
      amount: 19.99,
      date: DateTime.now(),
      category: Category.trabajo,
    ),
    Expense(
      title: 'Cinema',
      amount: 15.69,
      date: DateTime.now(),
      category: Category.ocio,
    ),
  ];

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
      _registeredExpenses.add(expense);
    });
  }

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

  void _selectScreen(String identifier) {
    Navigator.of(context).pop(); // Cierra el Drawer al seleccionar una opción

    if (identifier == 'gastos') {
      Navigator.of(context).pushReplacementNamed('/blank');
    } else if (identifier == 'estadisticas') {
      Navigator.of(context).pushReplacementNamed('/blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
          : Row(children: [
              Expanded(
                child: Chart(expenses: _registeredExpenses),
              ),
              Expanded(
                child: mainContent,
              ),
            ]),
    );
  }
}
