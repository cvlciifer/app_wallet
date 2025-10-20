import 'package:app_wallet/library_section/main_library.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADMIN WALLET',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: ChangeNotifierProvider(
        create: (context) => LoginProvider(),
        child: const LoginScreen(),
      ),
      routes: {
        '/home-page': (ctx) => const WalletHomePage(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
      backgroundColor: AwColors.white,
      appBar: null,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AwSpacing.xl,
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: AwColors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const AwText.bold(
                          'ADMIN WALLET',
                          size: AwSize.s30,
                          color: AwColors.appBarColor,
                        ),
                      ),
                    ),
                  ),
                  AwSpacing.xl,
                  const AwText.bold(
                    'Accede a tu cuenta',
                    size: AwSize.s20,
                    color: AwColors.boldBlack,
                  ),
                  AwSpacing.s10,
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      fillColor: AwColors.greyLight,
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  AwSpacing.s10,
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      fillColor: AwColors.greyLight,
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  AwSpacing.s10,
                  if (_errorMessage != null)
                    AwText(
                      text: _errorMessage!,
                      color: AwColors.red,
                    ),
                  AwSpacing.s10,
                  WalletButton.textButton(
                    buttonText: '¿Olvidaste tu contraseña?',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ForgotPasswordScreen()),
                      );
                    },
                  ),
                  AwSpacing.s20,
                  Center(
                    child: WalletButton.primaryButton(
                      buttonText: 'Acceder',
                      onPressed: () async {
                        setState(() {
                          _errorMessage = null;
                        });
                        if (_emailController.text.trim().isEmpty ||
                            _passwordController.text.trim().isEmpty) {
                          setState(() {
                            _errorMessage =
                                'Por favor, ingresa tu email y contraseña.';
                          });
                          return;
                        }
                        String emailPattern =
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                        RegExp regex = RegExp(emailPattern);
                        if (!regex.hasMatch(_emailController.text.trim())) {
                          setState(() {
                            _errorMessage =
                                'Por favor, ingresa un email válido.';
                          });
                          return;
                        }
                        if (_passwordController.text.trim().length < 6) {
                          setState(() {
                            _errorMessage =
                                'La contraseña debe tener al menos 6 caracteres.';
                          });
                          return;
                        }

                        final loginProvider =
                            Provider.of<LoginProvider>(context, listen: false);
                        await loginProvider.loginUser(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                          onSuccess: () {
                            // Ir a AuthWrapper para que se encargue del flujo (PIN / home)
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AuthWrapper()),
                            );
                          },
                          onError: (error) {
                            String translatedError;
                            if (error ==
                                'The supplied auth credential is incorrect, malformed or has expired.') {
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
                    ),
                  ),
                  AwSpacing.s20,
                  WalletButton.iconButtonText(
                    icon: Icons.g_translate,
                    buttonText: 'Continuar con Google',
                    onPressed: () async {
                      setState(() {
                        _errorMessage = null;
                      });

                      final loginProvider =
                          Provider.of<LoginProvider>(context, listen: false);

                      await loginProvider.signInWithGoogle(
                        onSuccess: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AuthWrapper()),
                          );
                        },
                        onError: (error) {
                          setState(() {
                            _errorMessage = error;
                          });
                        },
                      );
                    },
                  ),
                  AwSpacing.s20,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AwText(text: '¿No tienes una cuenta? '),
                      WalletButton.textButton(
                        buttonText: ' Registrarse',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RegisterScreen()),
                          );
                        },
                      ),
                    ],
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
