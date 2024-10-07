import 'package:flutter/material.dart';

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
  bool _isPasswordVisible = false; // Controla la visibilidad de la contraseña
  bool _isConfirmPasswordVisible = false; // Controla la visibilidad de la confirmación

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Registrarse'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre o Alias',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setState(() {
                      _areEmailsMatching =
                          _emailController.text == _confirmEmailController.text;
                    });
                  },
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _confirmEmailController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setState(() {
                      _areEmailsMatching =
                          _emailController.text == _confirmEmailController.text;
                    });
                  },
                ),
                if (!_areEmailsMatching)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Los correos no coinciden',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.left,
                    ),
                  ),
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
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
                  obscureText: !_isPasswordVisible,
                  onChanged: (value) {
                    setState(() {
                      _isPasswordLengthValid = value.length >= 8;
                      _isPasswordUppercaseValid =
                          value.contains(RegExp(r'[A-Z]'));
                      _arePasswordsMatching =
                          _passwordController.text ==
                              _confirmPasswordController.text;
                    });
                  },
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    _buildValidationChip(
                      label: 'Mínimo 8 caracteres',
                      isValid: _isPasswordLengthValid,
                    ),
                    SizedBox(width: 10),
                    _buildValidationChip(
                      label: 'Al menos una mayúscula',
                      isValid: _isPasswordUppercaseValid,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isConfirmPasswordVisible,
                  onChanged: (value) {
                    setState(() {
                      _arePasswordsMatching =
                          _passwordController.text ==
                              _confirmPasswordController.text;
                    });
                  },
                ),
                if (!_arePasswordsMatching)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Las contraseñas no coinciden',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.left,
                    ),
                  ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isPasswordLengthValid &&
                          _isPasswordUppercaseValid &&
                          _areEmailsMatching &&
                          _arePasswordsMatching
                      ? () {
                          // Lógica para registrarse
                          print('Registro exitoso');
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
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
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
    );
  }
}
