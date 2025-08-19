import 'package:flutter/material.dart';
import 'package:app_wallet/library/main_library.dart';

class WalletProfilePage extends StatefulWidget {
  final String? userEmail;
  final int totalExpenses;
  final int filteredExpenses;

  const WalletProfilePage({
    Key? key,
    this.userEmail,
    this.totalExpenses = 0,
    this.filteredExpenses = 0,
  }) : super(key: key);

  @override
  State<WalletProfilePage> createState() => _WalletProfilePageState();
}

class _WalletProfilePageState extends State<WalletProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WalletAppBar(
        title: AwText.bold(
          'Mi Perfil',
          color: AwColors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Usuario',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Text('Usuario: ${widget.userEmail ?? 'No disponible'}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email),
                      const SizedBox(width: 8),
                      Text('Correo: ${widget.userEmail ?? 'No disponible'}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Estadísticas
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estadísticas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.receipt_long),
                      const SizedBox(width: 8),
                      Text('Total de gastos: ${widget.totalExpenses}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.filter_list),
                      const SizedBox(width: 8),
                      Text('Gastos filtrados: ${widget.filteredExpenses}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Opciones
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configuración'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navegación a configuración
                    // Navigator.of(context).pushNamed('/settings');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Configuración próximamente')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'Cerrar sesión',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                  ),
                  onTap: () {
                    _showLogOutDialog();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLogOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Aquí iría la lógica de cerrar sesión
                // LogOutDialog.showLogOutDialog(context);
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }
}
