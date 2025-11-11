import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/profile_section/presentation/screens/ingresos_page.dart';
import 'package:app_wallet/profile_section/presentation/screens/gastos_imprevistos_page.dart';
import 'package:app_wallet/profile_section/presentation/screens/recurrent_create_page.dart';
import 'package:app_wallet/profile_section/presentation/screens/recurrent_registry_page.dart';

class WalletProfilePage extends ConsumerStatefulWidget {
  final String? userEmail;

  const WalletProfilePage({Key? key, this.userEmail}) : super(key: key);

  @override
  ConsumerState<WalletProfilePage> createState() => _WalletProfilePageState();
}

class _WalletProfilePageState extends ConsumerState<WalletProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  late String? userEmail;
  late String? userName;
  String? alias;

  @override
  void initState() {
    super.initState();

    userEmail = user?.email;
    userName = user?.displayName;
    _loadAlias();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      await Connectivity().checkConnectivity();
    } catch (_) {
      // ignorar
    }
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
      // ignorar errores al leer el alias
    }
  }

  String getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '';
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AwColors.greyLight,
      appBar: const WalletAppBar(
        title: AwText.normal('Mi Wallet', color: AwColors.white),
        actions: [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            AwSpacing.m,
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
                          alias != null && alias!.isNotEmpty
                              ? 'Hola, $alias 👋'
                              : 'Hola...👋',
                          color: AwColors.modalPurple,
                          size: AwSize.s16,
                          textOverflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        AwSpacing.s6,
                        AwText.bold(
                          userEmail ?? 'correo@ejemplo.com',
                          color: AwColors.boldBlack,
                          size: AwSize.s16,
                          textOverflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        AwSpacing.s6,
                        UnderlinedButton(
                          text: 'Cerrar sesión',
                          icon: Icons.logout,
                          color: AwColors.red,
                          alignment: Alignment.centerLeft,
                          onTap: () {
                            LogOutDialog.showLogOutDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AwSpacing.s20,
            const Align(
              alignment: Alignment.centerLeft,
              child: AwText.bold('Configuraciones',
                  color: AwColors.blue, size: AwSize.s18),
            ),
            AwSpacing.s12,
            SizedBox(
              width: double.infinity,
              child: SettingsCard(
                title: 'Gastos recurrentes',
                icon: Icons.repeat,
                onTap: () async {
                  try {
                    final result = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const RecurrentCreatePage()));
                    if (result == true) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gasto recurrente creado')));
                    }
                  } catch (_) {}
                },
              ),
            ),
            AwSpacing.s6,
            SizedBox(
              width: double.infinity,
              child: SettingsCard(
                title: 'Registro de gastos recurrentes',
                icon: Icons.list_alt,
                onTap: () async {
                  try {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecurrentRegistryPage()));
                  } catch (_) {}
                },
              ),
            ),
            AwSpacing.s12,
            SizedBox(
              width: double.infinity,
              child: SettingsCard(
                title: 'Actualizar alias',
                icon: Icons.person_outline,
                onTap: () {
                  () async {
                    try {
                      final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AliasInputPage(initialSetup: false)));
                      if (result != null && result.isNotEmpty) {
                        setState(() {
                          alias = result;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Alias actualizado: $result')));
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('No se pudo abrir cambiar alias')));
                    }
                  }();
                },
              ),
            ),
            AwSpacing.s,
            SizedBox(
              width: double.infinity,
              child: SettingsCard(
                title: 'Restablecer mi PIN',
                icon: Icons.lock_reset,
                onTap: () async {
                  final loader = ref.read(globalLoaderProvider.notifier);
                  loader.state = true;
                  try {
                    final uid = user?.uid;
                    final pinService = PinService();
                    final remaining = await pinService.pinChangeRemainingCount(
                        accountId: uid ?? '');
                    final blockedUntil = await pinService
                        .pinChangeBlockedUntilNextDay(accountId: uid ?? '');

                    final isBlocked = (remaining <= 0) ||
                        (blockedUntil != null && blockedUntil > Duration.zero);

                    try {
                      loader.state = false;
                    } catch (_) {}

                    if (isBlocked) {
                      final remainingDuration =
                          blockedUntil ?? const Duration(days: 1);
                      if (!mounted) return;
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PinLockedPage(
                                remaining: remainingDuration,
                                accountId: uid,
                                allowBack: true,
                              )));
                    } else {
                      try {
                        final success = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                                builder: (_) => const ForgotPinPage()));
                        if (success == true) {
                          if (!mounted) return;
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const SetPinPage()));
                        }
                      } catch (e, st) {
                        if (kDebugMode)
                          debugPrint('Restablecer PIN error: $e\n$st');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'No se pudo abrir restablecer PIN')));
                        }
                      }
                    }
                  } catch (e, st) {
                    if (kDebugMode)
                      debugPrint('Error checking PIN state: $e\n$st');
                    try {
                      loader.state = false;
                    } catch (_) {}
                  }
                },
              ),
            ),
            AwSpacing.s12,
            SizedBox(
              width: double.infinity,
              child: SettingsCard(
                title: 'Ingresos mensuales',
                icon: Icons.attach_money,
                onTap: () async {
                  try {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const IngresosPage()),
                    );
                    if (result == true) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresos guardados')));
                      }
                    }
                  } catch (_) {}
                },
              ),
            ),
            AwSpacing.s6,
            SizedBox(
              width: double.infinity,
              child: SettingsCard(
                title: 'Ingresos imprevistos',
                icon: Icons.money_off,
                onTap: () async {
                  try {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const GastosImprevistosPage()),
                    );
                    if (result == true) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingreso imprevisto guardado')));
                      }
                    }
                  } catch (_) {}
                },
              ),
            ),
            AwSpacing.s18,
          ],
        ),
      ),
    );
  }
}
