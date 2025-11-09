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

class _WelcomeIntroScreenState extends State<WelcomeIntroScreen> with TickerProviderStateMixin {
  String _title = 'Bienvenido a Admin Wallet';
  String _subtitle =
      'Admin Wallet, es tu agenda virtual que te ayudará a gestionar de mejor forma tus gastos en el día a día.';

  late final AnimationController _cardController;
  late final AnimationController _contentController;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;

  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadRemoteWelcomeMessage();
  }

  void _initAnimations() {
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardSlide = Tween<Offset>(begin: const Offset(0, -0.9), end: Offset.zero).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.0, 0.45, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.0, 0.45, curve: Curves.easeOut)),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.30, 0.7, curve: Curves.easeOut)),
    );
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.30, 0.7, curve: Curves.easeOut)),
    );

    _iconScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.55, 1.0, curve: Curves.elasticOut)),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.55, 1.0, curve: Curves.easeOut)),
    );

    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.80, 1.0, curve: Curves.easeOut)),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.80, 1.0, curve: Curves.easeOut)),
    );

    _cardController.forward().then((_) {
      if (mounted) _contentController.forward();
    });
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

    // Use a subtle fade transition to the next screen
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Static background (no gradient)
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
                child: SlideTransition(
                  position: _cardSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      // Make the card occupy most of the vertical space
                      height: MediaQuery.of(context).size.height * 0.72,
                      child: TicketCard(
                        roundTopCorners: true,
                        topCornerRadius: 20,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              // Top content grouped so it doesn't stretch
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AwSpacing.s18,
                                  // Title with fade + slide (more prominent)
                                  SlideTransition(
                                    position: _titleSlide,
                                    child: FadeTransition(
                                      opacity: _titleOpacity,
                                      child: Text(
                                        _title,
                                        textAlign: TextAlign.left,
                                        style: const TextStyle(
                                          color: AwColors.appBarColor,
                                          fontSize: AwSize.s22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  AwSpacing.s20,
                                  FadeTransition(
                                    opacity: _iconOpacity,
                                    child: ScaleTransition(
                                      scale: _iconScale,
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 120,
                                        color: AwColors.appBarColor,
                                      ),
                                    ),
                                  ),
                                  AwSpacing.s30,
                                  SlideTransition(
                                    position: _subtitleSlide,
                                    child: FadeTransition(
                                      opacity: _subtitleOpacity,
                                      child: Text(
                                        _subtitle,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AwColors.black,
                                          fontSize: AwSize.s16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  AwSpacing.s30,
                                ],
                              ),
                              const Spacer(),
                              FadeTransition(
                                opacity: _buttonOpacity,
                                child: SlideTransition(
                                  position: _buttonSlide,
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
                              ),
                            ],
                          ),
                        ),
                      ),
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

  @override
  void dispose() {
    _cardController.dispose();
    _contentController.dispose();
    // _bgController removed
    super.dispose();
  }
}
