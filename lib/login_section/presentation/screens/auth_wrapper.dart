import 'package:app_wallet/library_section/main_library.dart';
import 'dart:developer';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Esperar un poco para mostrar el splash
      await Future.delayed(const Duration(seconds: 2));

      final isLoggedIn = await _authService.isUserLoggedIn();

      if (mounted) {
        log('AuthWrapper: isLoggedIn=$isLoggedIn');
        if (isLoggedIn) {
          // Usuario ya está logueado: si tiene PIN pedirlo, si no ir al home
          final uid = _authService.getCurrentUser()?.uid;
          if (uid == null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
            return;
          }
          final pinService = PinService();
          // si borra la app e instala de nuevo, limpiar PIN/alias previo
          await pinService.clearOnReinstallIfNeeded(accountId: uid);
          final hasPin = await pinService.hasPin(accountId: uid);
          log('AuthWrapper: uid=$uid hasPin=$hasPin');

          if (hasPin) {
            // Si el pin
            final alias = await pinService.getAlias(accountId: uid);
            if (alias == null || alias.isEmpty) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) =>
                        const AliasInputPage(initialSetup: false)),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const EnterPinPage()),
              );
            }
          } else {
            // Si no hay PIN configurado, primero pedir alias y luego crear el PIN
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) =>
                      const AliasInputPage(initialSetup: true)),
            );
          }
        } else {
          final savedUid = await _authService.getSavedUid();
          if (savedUid != null) {
            try {
              final pinService = PinService();
              final hasPin = await pinService.hasPin(accountId: savedUid);
              if (hasPin) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => EnterPinPage(accountId: savedUid)),
                );
                return;
              }
            } catch (_) {}
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LoginScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // En caso de error, ir al login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: AwColors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: AwColors.black.withOpacity(0.2),
                    blurRadius: 10.0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AwSpacing.s30,
                  Text(
                    'Bienvenido a AdminWallet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AwSpacing.s50,
                  WalletLoader(),
                  AwSpacing.s50,
                  Text(
                    'Verificando sesión...',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
