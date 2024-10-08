import 'package:flutter/material.dart';
import 'package:app_wallet/screens/forgot_passoword.dart';
import 'package:app_wallet/screens/register.dart';
import 'package:app_wallet/screens/expenses.dart'; 
import 'package:app_wallet/services_bd/login_provider.dart'; 
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
        '/expense': (ctx) => Expenses(), 
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
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.wallet),
            SizedBox(width: 20),
            Text(
              'AdminWallet',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
        centerTitle: false,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accede a tu cuenta',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Introduce tu email y contraseña para acceder a tu cuenta',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 50),
                const Text(
                  'Ingresa tu Email',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Tu contraseña',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
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
                        MaterialPageRoute(
                            builder: (context) => ForgotPasswordScreen()),
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
                          _errorMessage = 'Por favor, ingresa un email válido.';
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
                          Navigator.pushReplacementNamed(context, '/expense');
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
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 40.0),
                      child: Text(
                        'Ingresar',
                        style: TextStyle(fontSize: 18),
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
                          MaterialPageRoute(
                              builder: (context) => RegisterScreen()),
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
    );
  }
}
