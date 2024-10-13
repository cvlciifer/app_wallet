import 'package:app_wallet/services_bd/register_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordLengthValid = false;
  bool _isPasswordUppercaseValid = false;
  bool _areEmailsMatching = true;
  bool _arePasswordsMatching = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Contenido de la pantalla
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                      0.9), // Color de fondo del cuadro con opacidad
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Regístrate en AdminWallet',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Con esta aplicación tendrás una gestión económica más optimizada.',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre o Alias',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        setState(() {
                          _areEmailsMatching = _emailController.text ==
                              _confirmEmailController.text;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _confirmEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        setState(() {
                          _areEmailsMatching = _emailController.text ==
                              _confirmEmailController.text;
                        });
                      },
                    ),
                    if (!_areEmailsMatching)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Los correos no coinciden',
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
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
                      obscureText: !_isPasswordVisible,
                      onChanged: (value) {
                        setState(() {
                          _isPasswordLengthValid = value.length >= 8;
                          _isPasswordUppercaseValid =
                              value.contains(RegExp(r'[A-Z]'));
                          _arePasswordsMatching = _passwordController.text ==
                              _confirmPasswordController.text;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 10.0,
                        children: [
                          _buildValidationChip(
                              label: 'Mínimo 8 caracteres',
                              isValid: _isPasswordLengthValid),
                          _buildValidationChip(
                              label: 'Al menos una mayúscula',
                              isValid: _isPasswordUppercaseValid),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isConfirmPasswordVisible,
                      onChanged: (value) {
                        setState(() {
                          _arePasswordsMatching = _passwordController.text ==
                              _confirmPasswordController.text;
                        });
                      },
                    ),
                    if (!_arePasswordsMatching)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Las contraseñas no coinciden',
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isPasswordLengthValid &&
                              _isPasswordUppercaseValid &&
                              _areEmailsMatching &&
                              _arePasswordsMatching
                          ? () async {
                              final String email = _emailController.text.trim();
                              final String username =
                                  _nameController.text.trim();
                              final String password =
                                  _passwordController.text.trim();

                              // Obtén una instancia de RegisterProvider usando context.read
                              final registerProvider =
                                  context.read<RegisterProvider>();

                              // Llama a registerUser con await y verifica el estado del widget
                              try {
                                await registerProvider.registerUser(
                                  email: email,
                                  username: username,
                                  password: password,
                                  token: '',
                                  onSuccess: () {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(Icons.account_balance_wallet,
                                                  color: Colors.white),
                                              SizedBox(width: 10),
                                              Text(
                                                  '¡Felicitaciones, ya has creado tu propia cuenta!'),
                                            ],
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                      Future.delayed(const Duration(seconds: 3),
                                          () {
                                        Navigator.pop(context);
                                      });
                                    }
                                  },
                                  onError: (error) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(error)),
                                      );
                                    }
                                  },
                                );
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Error al registrar: $e')),
                                  );
                                }
                              }
                            }
                          : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 40.0),
                        child: Text(
                          'Registrarse',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationChip({required String label, required bool isValid}) {
    Color chipColor;
    if (isValid) {
      chipColor = Colors.green;
    } else if (_passwordController.text.isEmpty) {
      chipColor = Colors.grey;
    } else {
      chipColor = Colors.red;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
    );
  }
}
