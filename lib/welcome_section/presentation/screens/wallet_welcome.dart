import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/welcome_section/presentation/screens/welcome_intro.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // _checked removed; not used

  @override
  void initState() {
    super.initState();
    _decideNext();
  }

  Future<void> _decideNext() async {
    final prefs = await SharedPreferences.getInstance();
    final seenIntro = prefs.getBool('seen_welcome_intro') ?? false;

    // Mostrar splash 2 segundos para efecto visual
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (seenIntro) {
      Navigator.of(context).pushReplacementNamed('/logIn');
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeIntroScreen()),
      );
    }

    // no local state needed after navigation
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AwSpacing.s30,
            AwSpacing.s50,
            WalletLoader(),
            AwSpacing.s50,
            Text(
              'Preparando la App...',
              style: TextStyle(
                fontSize: AwSize.s18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
