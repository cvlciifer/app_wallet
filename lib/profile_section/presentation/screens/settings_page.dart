import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:provider/provider.dart' as prov;

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? alias;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold('Configuraciones', color: AwColors.white),
        automaticallyImplyLeading: true,
        actions: [],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SettingsCard(
                    title: 'Actualizar Alias',
                    icon: Icons.person_outline,
                    onTap: () {
                      () async {
                        try {
                          final result = await Navigator.of(context).push<String>(
                              MaterialPageRoute(builder: (_) => const AliasInputPage(initialSetup: false)));
                          if (result != null && result.isNotEmpty) {
                            try {
                              final aliasProvider = prov.Provider.of<AliasProvider>(context, listen: false);
                              aliasProvider.setAlias(result);
                            } catch (_) {}
                            setState(() {
                              alias = result;
                            });
                          }
                        } catch (e) {
                          WalletPopup.showNotificationWarningOrange(
                            context: context,
                            message: 'No se pudo abrir cambiar alias',
                            visibleTime: 2,
                            isDismissible: true,
                          );
                        }
                      }();
                    },
                  ),
                ),
                AwSpacing.s10,
                SizedBox(
                  width: double.infinity,
                  child: SettingsCard(
                    title: 'Restablecer PIN',
                    icon: Icons.lock_reset,
                    onTap: () async {
                      final connectivity = await Connectivity().checkConnectivity();
                      if (connectivity == ConnectivityResult.none) {
                        if (!mounted) return;
                        WalletPopup.showNotificationWarningOrange(
                          context: context,
                          message: 'No es posible restablecer el PIN sin conexión',
                          visibleTime: 2,
                          isDismissible: true,
                        );
                        return;
                      }
                      final loader = ref.read(globalLoaderProvider.notifier);
                      loader.state = true;
                      try {
                        final uid = user?.uid;
                        final pinService = PinService();
                        final remaining = await pinService.pinChangeRemainingCount(accountId: uid ?? '');
                        final blockedUntil = await pinService.pinChangeBlockedUntilNextDay(accountId: uid ?? '');

                        final isBlocked = (remaining <= 0) || (blockedUntil != null && blockedUntil > Duration.zero);

                        try {
                          loader.state = false;
                        } catch (_) {}

                        if (isBlocked) {
                          final remainingDuration = blockedUntil ?? const Duration(days: 1);
                          if (!mounted) return;
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => PinLockedPage(
                                    remaining: remainingDuration,
                                    accountId: uid,
                                    allowBack: true,
                                  )));
                        } else {
                          try {
                            final success = await Navigator.of(context)
                                .push<bool>(MaterialPageRoute(builder: (_) => const ForgotPinPage()));
                            if (success == true) {
                              if (!mounted) return;
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SetPinPage()));
                            }
                          } catch (e, st) {
                            if (kDebugMode) {
                              log('Restablecer PIN error', error: e, stackTrace: st);
                            }
                            if (mounted) {
                              WalletPopup.showNotificationWarningOrange(
                                context: context,
                                message: 'No se pudo abrir restablecer PIN',
                                visibleTime: 2,
                                isDismissible: true,
                              );
                            }
                          }
                        }
                      } catch (e, st) {
                        if (kDebugMode) {
                          log('Error checking PIN state', error: e, stackTrace: st);
                        }
                        try {
                          loader.state = false;
                        } catch (_) {}
                      }
                    },
                  ),
                ),
                AwSpacing.s10,
                SizedBox(
                  width: double.infinity,
                  child: SettingsCard(
                    title: 'Términos y condiciones',
                    icon: Icons.note_alt_sharp,
                    onTap: () async {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TermsPage(readOnly: true)),
                      );
                    },
                  ),
                ),
                AwSpacing.xl,
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: ImageFiltered(
                                imageFilter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                                child: FractionallySizedBox(
                                  widthFactor: 0.75,
                                  child: Container(
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: const ui.Color.fromARGB(66, 138, 137, 137),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Center(
                            child: Image(
                              image: AWImage.settings,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
