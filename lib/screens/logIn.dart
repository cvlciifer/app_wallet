import 'package:flutter/material.dart';
import 'package:app_wallet/screens/forgot_passoword.dart';
import 'package:app_wallet/screens/register.dart';
import 'package:app_wallet/screens/expenses.dart'; // Importa la pantalla de Expenses
import 'package:app_wallet/services_bd/login_provider.dart'; // Importa tu LoginProvider
import 'package:provider/provider.dart'; // Importar el provider

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
        create: (context) => LoginProvider(), // Proveedor de Login
        child: LoginScreen(),
      ),
      routes: {
        '/expense': (ctx) => Expenses(), // Agrega la ruta para Expenses
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
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
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
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Navega a la pantalla de recuperación de contraseña
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen()),
                    );
                  },
                  child: Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Lógica para iniciar sesión
                  setState(() {
                    _errorMessage = null; // Reiniciar el mensaje de error
                  });

                  final loginProvider =
                      Provider.of<LoginProvider>(context, listen: false);
                  await loginProvider.loginUser(
                    email: _emailController.text,
                    password: _passwordController.text,
                    onSuccess: () {
                      // Navegar a la pantalla de Expenses
                      Navigator.pushReplacementNamed(context, '/expense');
                    },
                    onError: (error) {
                      // Mostrar el error en la UI
                      setState(() {
                        _errorMessage = error;
                      });
                    },
                  );
                },
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 40.0),
                  child: Text(
                    'Continuar',
                    style: TextStyle(fontSize: 18),
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
                      // Navega a la pantalla de registro
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
    );
  }
}
