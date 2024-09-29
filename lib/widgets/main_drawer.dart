import 'package:flutter/material.dart';
import 'package:app_wallet/screens/estadisticas_screen.dart';
import 'package:app_wallet/screens/informe_mensual.dart'; 
import 'package:app_wallet/services_bd/firebase_Service.dart';
import 'package:app_wallet/models/expense.dart'; 

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    super.key,
    required this.onSelectScreen,
    required this.expenses, // Añadir este parámetro
  });

  final void Function(String identifier) onSelectScreen;
  final List<Expense> expenses; // Variable para almacenar la lista de gastos

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wallet,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 18),
                Text(
                  'Mi Billetera',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.change_circle_outlined,
              size: 26,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            title: Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 24,
                  ),
            ),
            onTap: () {
              onSelectScreen('filtros');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.arrow_upward_rounded,
              size: 26,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            title: Text(
              'Estadisticas',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 24,
                  ),
            ),
            onTap: () {
              onSelectScreen('estadisticas');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => EstadisticasScreen(
                      expenses: expenses), // Pasar la lista de gastos
                ),
              );
            },
          ),
          // Nueva opción en el Drawer para Informe Mensual
          ListTile(
            leading: Icon(
              Icons.insert_chart_outlined, // Icono para la nueva pantalla
              size: 26,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            title: Text(
              'Informe Mensual',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 24,
                  ),
            ),
            onTap: () {
              onSelectScreen('informe_mensual');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => InformeMensualScreen(
                    expenses: expenses, // Pasar la lista de gastos a la nueva pantalla
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.question_answer,
              size: 26,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            title: Text(
              'Obtener Consejo',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 24,
                  ),
            ),
            onTap: () async {
              // Cierra el Drawer
              Navigator.of(context).pop();
              // Obtén el consejo y muestra el Dialog en el contexto correcto
              var consejoData = await getRandomConsejo();
              // Usa `Future.delayed` para evitar problemas con el contexto
              Future.delayed(Duration.zero, () {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Tu consejo diario'),
                      content: Text(
                          consejoData['consejo'] ?? 'Consejo no disponible'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Cierra el Dialog
                          },
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
