import 'dart:developer';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/profile_section/presentation/screens/header_label.dart';
import 'package:app_wallet/profile_section/presentation/screens/settings_page.dart';
import 'package:app_wallet/components_section/widgets/home_income_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as prov;

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

  @override
  void initState() {
    super.initState();

    userEmail = user?.email;
    userName = user?.displayName;
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      await Connectivity().checkConnectivity();
    } catch (_) {}
  }

  String getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '';
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final aliasFromProvider = prov.Provider.of<AliasProvider>(context).alias;
    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold('Mi Wallet', color: AwColors.white),
        actions: [],
      ),
      body: Column(
        children: [
          AwSpacing.m,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: HeaderLabel(
              cardStyle: true,
              // muestra resumen de ingresos al voltear la tarjeta
              backChild: HomeIncomeSummary(
                controller: prov.Provider.of<WalletExpensesController>(context, listen: false),
              ),
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
                          aliasFromProvider != null && aliasFromProvider.isNotEmpty
                              ? 'Hola, $aliasFromProvider 👋'
                              : 'Hola...👋',
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: AwText.normal(
                                "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}",
                                color: AwColors.white.withOpacity(0.95),
                                size: AwSize.s14,
                                textOverflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
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
          AwSpacing.s20,
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AwText.bold('Menú', color: AwColors.blue, size: AwSize.s18),
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
                          title: 'Ingresos imprevistos',
                          icon: Icons.savings,
                          onTap: () async {
                            try {
                              final result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => const IngresosImprevistosPage(),
                                ),
                              );
                              if (!mounted) return;
                              if (result == true) {
                                WalletPopup.showNotificationSuccess(
                                  context: context,
                                  title: 'Ingreso imprevisto guardado',
                                  visibleTime: 2,
                                  isDismissible: true,
                                );
                              }
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
                            final connectivity = await Connectivity().checkConnectivity();
                            if (connectivity == ConnectivityResult.none) {
                              if (!mounted) return;
                              WalletPopup.showNotificationWarningOrange(
                                // ignore: use_build_context_synchronously
                                context: context,
                                message: 'No es posible abrir correos sin conexión',
                                visibleTime: 2,
                                isDismissible: true,
                              );
                              return;
                            }
                            try {
                              await Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => const GmailInboxPage()));
                            } catch (e) {
                              if (kDebugMode) log('Error abriendo GmailInboxPage: $e');
                              if (mounted) {
                                WalletPopup.showNotificationWarningOrange(
                                  // ignore: use_build_context_synchronously
                                  context: context,
                                  message: 'No es posible abrir la bandeja de correos',
                                  visibleTime: 2,
                                  isDismissible: true,
                                );
                                return;
                              }
                            }
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
                          title: 'Configuración',
                          icon: Icons.settings,
                          onTap: () async {
                            try {
                              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
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
