import 'package:app_wallet/library/main_library.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChangeNotifierProvider(
        create: (context) => LoginProvider(),
        child: LoginScreen(),
      ),
      routes: {
        '/home-page': (ctx) => const WalletHomePage(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WalletAppBar(
        title: AwText.bold(
          'ADMIN WALLET',
          color: AwColors.white,
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AwText.bold(
                        'Accede a tu cuenta',
                        size: AwSize.s20,
                        color: AwColors.boldBlack,
                      ),
                      const Text(
                        'Introduce tu email y contraseña para acceder a tu cuenta',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                      const AwText.bold(
                        'Ingresa tu Email',
                        size: AwSize.s16,
                        color: AwColors.boldBlack,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          fillColor: Colors.white.withOpacity(0.8),
                          labelText: 'Email',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 30),
                      const AwText.bold(
                        'Tu contraseña',
                        size: AwSize.s16,
                        color: AwColors.boldBlack,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                            );
                          },
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              _errorMessage = null;
                            });
                            if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
                              setState(() {
                                _errorMessage = 'Por favor, ingresa tu email y contraseña.';
                              });
                              return;
                            }
                            String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                            RegExp regex = RegExp(emailPattern);
                            if (!regex.hasMatch(_emailController.text.trim())) {
                              setState(() {
                                _errorMessage = 'Por favor, ingresa un email válido.';
                              });
                              return;
                            }
                            if (_passwordController.text.trim().length < 6) {
                              setState(() {
                                _errorMessage = 'La contraseña debe tener al menos 6 caracteres.';
                              });
                              return;
                            }

                            final loginProvider = Provider.of<LoginProvider>(context, listen: false);
                            await loginProvider.loginUser(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                              onSuccess: () {
                                Navigator.pushReplacementNamed(context, '/home-page');
                              },
                              onError: (error) {
                                String translatedError;
                                if (error == 'The supplied auth credential is incorrect, malformed or has expired.') {
                                  translatedError =
                                      'Las credenciales de autenticación proporcionadas son incorrectas, están mal formadas o han expirado.';
                                } else {
                                  translatedError = error;
                                }

                                setState(() {
                                  _errorMessage = translatedError;
                                });
                              },
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 40.0),
                            child: Text(
                              'Ingresar',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Divider con texto "O"
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              color: Colors.grey[400],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'O',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            setState(() {
                              _errorMessage = null;
                            });

                            final loginProvider = Provider.of<LoginProvider>(context, listen: false);

                            await loginProvider.signInWithGoogle(
                              onSuccess: () {
                                Navigator.pushReplacementNamed(context, '/home-page');
                              },
                              onError: (error) {
                                setState(() {
                                  _errorMessage = error;
                                });
                              },
                            );
                          },
                          icon: Image.network(
                            'https://developers.google.com/identity/images/g-logo.png',
                            height: 24,
                            width: 24,
                          ),
                          label: const Text(
                            'Continuar con Google',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿No tienes una cuenta?'),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RegisterScreen()),
                              );
                            },
                            child: const Text('Registrarse'),
                          ),
                        ],
                      ),
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
