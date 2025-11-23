import 'package:flutter/material.dart';
import 'package:app_wallet/library_section/main_library.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordLengthValid = false;
  bool _isPasswordUppercaseValid = false;
  bool _areEmailsMatching = true;
  bool _arePasswordsMatching = true;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AwColors.greyLight,
      appBar: const WalletAppBar(
        title: AwText.bold('Regístrate', color: AwColors.white),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TicketCard(
              notchDepth: 12,
              elevation: 6,
              color: AwColors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AwText.bold('Regístrate en AdminWallet', color: AwColors.boldBlack, size: AwSize.s20),
                    AwSpacing.s6,
                    const AwText.normal(
                      'Con esta aplicación tendrás una gestión económica más optimizada.',
                      size: AwSize.s14,
                      color: AwColors.modalGrey,
                    ),
                    AwSpacing.s18,
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre o Alias',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    AwSpacing.s20,
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
                          _areEmailsMatching = _emailController.text == _confirmEmailController.text;
                        });
                      },
                    ),
                    AwSpacing.s20,
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
                          _areEmailsMatching = _emailController.text == _confirmEmailController.text;
                        });
                      },
                    ),
                    if (!_areEmailsMatching) ...[
                      AwSpacing.s6,
                      const AwText.normal('Los correos no coinciden', color: AwColors.red),
                    ],
                    AwSpacing.s20,
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      onChanged: (value) {
                        setState(() {
                          _isPasswordLengthValid = value.length >= 8;
                          _isPasswordUppercaseValid = value.contains(RegExp(r'[A-Z]'));
                          _arePasswordsMatching = _passwordController.text == _confirmPasswordController.text;
                        });
                      },
                    ),
                    AwSpacing.s10,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 10.0,
                        children: [
                          _buildValidationChip(label: 'Mínimo 8 caracteres', isValid: _isPasswordLengthValid),
                          _buildValidationChip(label: 'Al menos una mayúscula', isValid: _isPasswordUppercaseValid),
                        ],
                      ),
                    ),
                    AwSpacing.s20,
                    TextField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        ),
                      ),
                      obscureText: !_isConfirmPasswordVisible,
                      onChanged: (value) {
                        setState(() {
                          _arePasswordsMatching = _passwordController.text == _confirmPasswordController.text;
                        });
                      },
                    ),
                    if (!_arePasswordsMatching) ...[
                      AwSpacing.s6,
                      const AwText.normal('Las contraseñas no coinciden', color: AwColors.red),
                    ],
                    AwSpacing.s40,
                    WalletButton.primaryButton(
                      buttonText: 'Registrarse',
                      onPressed: _isPasswordLengthValid &&
                              _isPasswordUppercaseValid &&
                              _areEmailsMatching &&
                              _arePasswordsMatching
                          ? () async {
                              final String email = _emailController.text.trim();
                              final String username = _nameController.text.trim();
                              final String password = _passwordController.text.trim();
                              final registerProvider = context.read<RegisterProvider>();
                              try {
                                await registerProvider.registerUser(
                                  email: email,
                                  username: username,
                                  password: password,
                                  token: '',
                                  onSuccess: () {
                                    if (mounted) {
                                      final overlayCtx = Navigator.of(context).overlay?.context;
                                      Navigator.of(context).pop();
                                      if (overlayCtx != null) {
                                        Future.delayed(const Duration(milliseconds: 120), () {
                                          WalletPopup.showNotificationSuccess(
                                            context: overlayCtx,
                                            title: '¡Felicitaciones, ya has creado tu propia cuenta!',
                                          );
                                        });
                                      }
                                    }
                                  },
                                  onError: (error) {
                                    if (mounted) {
                                      WalletPopup.showNotificationError(context: context, title: error);
                                    }
                                  },
                                );
                              } catch (e) {
                                if (mounted) {
                                  WalletPopup.showNotificationError(context: context, title: 'Error al registrar: $e');
                                }
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationChip({required String label, required bool isValid}) {
    Color chipColor;
    if (isValid) {
      chipColor = AwColors.green;
    } else if (_passwordController.text.isEmpty) {
      chipColor = AwColors.grey;
    } else {
      chipColor = AwColors.red;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: AwColors.white),
      ),
      backgroundColor: chipColor,
    );
  }
}
