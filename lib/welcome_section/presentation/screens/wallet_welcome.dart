import 'package:app_wallet/library_section/main_library.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AwColors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
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
                      fontSize: AwSize.s24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AwSpacing.s50,
                  WalletLoader(),
                  AwSpacing.s50,
                  Text(
                    'Cargando la App de AdminWallet...',
                    style: TextStyle(
                      fontSize: AwSize.s18,
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
