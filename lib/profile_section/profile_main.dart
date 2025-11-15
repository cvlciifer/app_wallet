import 'dart:developer';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/profile_section/presentation/screens/header_label.dart';
import 'package:app_wallet/profile_section/presentation/screens/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    } catch (_) {}
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
    } catch (_) {}
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
        title: AwText.bold('Mi Wallet', color: AwColors.white),
        actions: [],
        barColor: AwColors.appBarColor,
        automaticallyImplyLeading: true,
      ),
      body: Column(
        children: [
          AwSpacing.m,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: HeaderLabel(
                cardStyle: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AwText.bold(
                            alias != null && alias!.isNotEmpty ? 'Hola, $alias 👋' : 'Hola...👋',
                            color: AwColors.white,
                            size: AwSize.s24,
                            textOverflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          AwSpacing.s6,
                          AwText.bold(
                            userEmail ?? '',
                            color: AwColors.white.withOpacity(0.95),
                            size: AwSize.s14,
                            textOverflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          AwSpacing.s6,
                          // Row que contiene la fecha a la izquierda y el botón 'Cerrar sesión' a la derecha
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AwText.normal(
                                // Fecha de hoy en formato DD/MM/YYYY
                                "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}",
                                color: AwColors.white.withOpacity(0.95),
                                size: AwSize.s14,
                                textOverflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              UnderlinedButton(
                                text: 'Cerrar sesión',
                                icon: Icons.logout,
                                color: AwColors.white,
                                onTap: () {
                                  LogOutDialog.showLogOutDialog(context);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AwSpacing.s20,
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AwText.bold(
                'Menú',
                color: AwColors.blue,
                size: AwSize.s18,
              ),
            ),
          ),
          AwSpacing.s12,
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SettingsCard(
                          title: 'Configuración',
                          icon: Icons.settings,
                          onTap: () async {
                            try {
                              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
                            } catch (_) {}
                          },
                        ),
                      ),
                      AwSpacing.s6,
                      SizedBox(
                        width: double.infinity,
                        child: SettingsCard(
                          title: 'Gastos recurrentes',
                          icon: Icons.repeat,
                          onTap: () async {
                            try {
                              final result = await Navigator.of(context)
                                  .push<bool>(MaterialPageRoute(builder: (_) => const RecurrentCreatePage()));
                              if (!mounted) return;
                              if (result == true) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(content: Text('Gasto recurrente creado')));
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
                              await Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => const RecurrentRegistryPage()));
                            } catch (_) {}
                          },
                        ),
                      ),
                      AwSpacing.s6,
                      SizedBox(
                        width: double.infinity,
                        child: SettingsCard(
                          title: 'Ver correos (Gmail)',
                          icon: Icons.email,
                          onTap: () async {
                            try {
                              await Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => const GmailInboxPage()));
                            } catch (e) {
                              if (kDebugMode) log('Error abriendo GmailInboxPage: $e');
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No se pudo abrir la bandeja de correos')));
                            }
                          },
                        ),
                      ),
                      AwSpacing.s6,
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
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(content: Text('Ingresos guardados')));
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
                          icon: Icons.savings,
                          onTap: () async {
                            try {
                              final result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(builder: (_) => const IngresosImprevistosPage()),
                              );
                              if (!mounted) return;
                              if (result == true) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(content: Text('Ingreso imprevisto guardado')));
                              }
                            } catch (_) {}
                          },
                        ),
                      ),
                      AwSpacing.s18,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
