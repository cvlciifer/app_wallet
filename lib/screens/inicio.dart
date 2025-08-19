import 'package:app_wallet/library/main_library.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.8, // Ajusta el ancho del contenedor
              padding: const EdgeInsets.all(
                  20.0), // Espaciado interno del contenedor
              decoration: BoxDecoration(
                color: Colors.white
                    // ignore: deprecated_member_use
                    .withOpacity(0.9), // Fondo blanco con transparencia
                borderRadius: BorderRadius.circular(20.0), // Bordes redondeados
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
                  SizedBox(height: 30),
                  Text(
                    'Bienvenido a AdminWallet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 50),
                  WalletLoader(),
                  SizedBox(height: 50),
                  Text(
                    'Cargando la App de AdminWallet...',
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
