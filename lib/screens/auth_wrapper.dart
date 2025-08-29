import 'package:app_wallet/library/main_library.dart';
import 'package:app_wallet/services_bd/auth_service.dart';

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
        if (isLoggedIn) {
          // Usuario ya está logueado, ir al home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const WalletHomePage(),
            ),
          );
        } else {
          // Usuario no está logueado, ir al login
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
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.2),
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
