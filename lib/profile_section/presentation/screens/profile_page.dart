import 'package:app_wallet/library_section/main_library.dart';

class WalletProfilePage extends StatefulWidget {
  final String? userEmail;
  final int totalExpenses;
  final double totalAmount;
  final List<Expense> expenses;

  const WalletProfilePage({
    Key? key,
    this.userEmail,
    this.totalExpenses = 0,
    this.totalAmount = 0,
    this.expenses = const [],
  }) : super(key: key);

  @override
  State<WalletProfilePage> createState() => _WalletProfilePageState();
}

// Devuelve una lista de mapas con nombre, ícono y total por categoría
List<Map<String, dynamic>> getCategoriasConTotal(List<Expense> expenses) {
  final Map<String, double> totales = {};
  for (var e in expenses) {
    String nombre = e.category.toString().split('.').last;
    totales[nombre] = (totales[nombre] ?? 0) + e.amount;
  }
  final List<Map<String, dynamic>> categorias = [];
  totales.forEach((nombre, total) {
    IconData icono;
    switch (nombre.toLowerCase()) {
      case 'viajes':
        icono = Icons.flight;
        break;
      case 'comida':
        icono = Icons.restaurant;
        break;
      case 'hogar':
        icono = Icons.home;
        break;
      case 'transporte':
        icono = Icons.directions_bus;
        break;
      case 'salud':
        icono = Icons.local_hospital;
        break;
      case 'educacion':
        icono = Icons.school;
        break;
      case 'entretenimiento':
        icono = Icons.movie;
        break;
      default:
        icono = Icons.category;
    }
    categorias.add({'nombre': nombre, 'icono': icono, 'total': total});
  });
  return categorias;
}

class _WalletProfilePageState extends State<WalletProfilePage> {
  // se obtiene el nombre y correo del usuario usando FirebaseAuth.
  final User? user = FirebaseAuth.instance.currentUser;
  late String? userEmail;
  late String? userName;
  String? alias;

  @override
  void initState() {
    super.initState();
    userEmail = user?.email;
    userName = user?.displayName;
    // Carga el alias almacenado
    _loadAlias();
  }

  Future<void> _loadAlias() async {
    final uid = user?.uid;
    if (uid == null) return;
    try {
      final pinService = PinService();
      final a = await pinService.getAlias(accountId: uid);
      if (a != null && a.isNotEmpty) {
        setState(() {
          alias = a;
        });
      }
    } catch (_) {
      // ignore errors reading alias
    }
  }

  String getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '';
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold(
          'Mi Perfil',
          color: AwColors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            AwSpacing.m,
            // Icono de usuario grande y centrado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AwColors.blue,
                    child: Icon(Icons.person, size: 40, color: AwColors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AwText.bold(
                          '¡Hola, ${alias ?? 'Alias no disponible'}!',
                          color: AwColors.modalPurple,
                          size: AwSize.s20,
                        ),
                        AwSpacing.s6,
                        AwText.bold(
                          userEmail ?? 'correo@ejemplo.com',
                          color: AwColors.boldBlack,
                          size: AwSize.s16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            // Estadísticas y categorías en columna, sin tarjetas
            AwSpacing.s12,
            Row(
              children: [
                const Icon(Icons.receipt_long, color: AwColors.blue, size: 32),
                const SizedBox(width: 12),
                const AwText.large('Cantidad de gastos:',
                    color: AwColors.boldBlack, size: AwSize.s20),
                const SizedBox(width: 8),
                AwText.large('${widget.totalExpenses}',
                    color: AwColors.modalPurple, size: AwSize.s20),
              ],
            ),
            AwSpacing.s18,
            const AwText.normal('Categorías',
                color: AwColors.boldBlack, size: AwSize.s16),
            AwSpacing.s,
            Column(
              children: getCategoriasConTotal(widget.expenses)
                  .map((cat) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(cat['icono'], color: AwColors.blue, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AwText.normal(cat['nombre'],
                                  color: AwColors.boldBlack, size: AwSize.s16),
                            ),
                            AwText.bold(formatNumber(cat['total']),
                                color: AwColors.modalPurple, size: AwSize.s16),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            AwSpacing.s18,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const AwText.bold('Total de gastos:',
                    color: AwColors.boldBlack, size: AwSize.s18),
                const SizedBox(width: 8),
                AwText.bold(formatNumber(widget.totalAmount),
                    color: AwColors.red, size: AwSize.s20),
              ],
            ),

            const Divider(height: 32),
            // Botón de configuración
            WalletButton.iconButtonText(
              icon: Icons.settings,
              buttonText: 'Configuración',
              iconColor: AwColors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configuración próximamente')),
                );
              },
            ),
            AwSpacing.s20,
            // Botón de cerrar sesión
            WalletButton.iconButtonText(
              icon: Icons.logout,
              buttonText: 'Cerrar sesión',
              iconColor: AwColors.white,
              backgroundColor: AwColors.red,
              onPressed: () {
                LogOutDialog.showLogOutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
