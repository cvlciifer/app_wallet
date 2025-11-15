import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_wallet/library_section/main_library.dart';

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
                    title: 'Actualizar alias',
                    icon: Icons.person_outline,
                    onTap: () {
                      () async {
                        try {
                          final result = await Navigator.of(context).push<String>(
                              MaterialPageRoute(builder: (_) => const AliasInputPage(initialSetup: false)));
                          if (result != null && result.isNotEmpty) {
                            setState(() {
                              alias = result;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text('Alias actualizado: $result')));
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('No se pudo abrir cambiar alias')));
                        }
                      }();
                    },
                  ),
                ),
                AwSpacing.s6,
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
                            if (kDebugMode) log('Restablecer PIN error', error: e, stackTrace: st);
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(content: Text('No se pudo abrir restablecer PIN')));
                            }
                          }
                        }
                      } catch (e, st) {
                        if (kDebugMode) log('Error checking PIN state', error: e, stackTrace: st);
                        try {
                          ref.read(globalLoaderProvider.notifier).state = false;
                        } catch (_) {}
                      }
                    },
                  ),
                ),
                AwSpacing.s18,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
