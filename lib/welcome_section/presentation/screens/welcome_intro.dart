import 'dart:developer';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class WelcomeIntroScreen extends StatefulWidget {
  const WelcomeIntroScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeIntroScreen> createState() => _WelcomeIntroScreenState();
}

class _WelcomeIntroScreenState extends State<WelcomeIntroScreen> {
  String _title = 'Bienvenido a Admin Wallet';
  String _subtitle =
      'Admin Wallet, es tu agenda virtual que te ayudará a gestionar de mejor forma tus gastos en el día a día.';

  @override
  void initState() {
    super.initState();
    _loadRemoteWelcomeMessage();
  }

  Future<void> _loadRemoteWelcomeMessage() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      final remoteValue = remoteConfig.getString('message_welcome');
      log('Valor remoto welcome_message: $remoteValue');
      if (remoteValue.isNotEmpty) {
        try {
          final data = jsonDecode(remoteValue);
          if (data is Map<String, dynamic>) {
            final remoteTitle = data['title'] as String?;
            log('Mensaje remoto cargado: $remoteTitle');
            final remoteSubtitle = data['subtitle'] as String?;
            log('Mensaje remoto cargado: $remoteSubtitle');
            if (mounted) {
              setState(() {
                if (remoteTitle != null && remoteTitle.isNotEmpty) _title = remoteTitle;
                if (remoteSubtitle != null && remoteSubtitle.isNotEmpty) _subtitle = remoteSubtitle;
              });
            }
          } else if (mounted) {
            setState(() => _subtitle = remoteValue);
          }
        } catch (e) {
          if (mounted) setState(() => _subtitle = remoteValue);
        }
      }
    } catch (e) {
      log('Error cargando mensaje remoto: $e');
    }
  }

  Future<void> _onContinue(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_welcome_intro', true);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WalletAppBar(
        barColor: AwColors.appBarColor,
        showCloseIcon: false,
        showWalletIcon: false,
      ),
      backgroundColor: AwColors.greyLight,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AwSpacing.s18,
                      Text(
                        _title,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: AwColors.appBarColor,
                          fontSize: AwSize.s22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AwSpacing.s20,
                      Text(
                        _subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AwColors.black,
                          fontSize: AwSize.s16,
                        ),
                      ),
                      AwSpacing.s30,
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 120,
                        color: AwColors.appBarColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: AwColors.appBarColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () => _onContinue(context),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: AwSize.s16,
                      fontWeight: FontWeight.bold,
                      color: AwColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
