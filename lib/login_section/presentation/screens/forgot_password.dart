import 'package:app_wallet/library_section/main_library.dart' hide AuthProvider;
import 'package:app_wallet/login_section/presentation/providers/reset_password.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: AwColors.greyLight),
          Center(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AwText.bold(
                        '¿Has olvidado tu contraseña?',
                        size: AwSize.s24,
                        color: AwColors.appBarColor,
                      ),
                    ),
                    AwSpacing.s12,
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AwText.normal(
                        'Ingresa tu correo con el que iniciaste sesión para enviarte instrucciones de restablecimiento.',
                        size: AwSize.s14,
                        color: AwColors.boldBlack,
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
                    ),
                    AwSpacing.s20,
                    WalletButton.iconButtonText(
                      buttonText: 'Enviar al Email',
                      onPressed: () {
                        final email = _emailController.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Por favor, ingresa tu correo.')),
                          );
                          return;
                        }

                        Provider.of<AuthProvider>(context, listen: false)
                            .resetPassword(
                          email,
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Se ha enviado un enlace de restablecimiento a $email.')),
                            );
                            Navigator.of(context).pop();
                          },
                          (errorMessage) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMessage)),
                            );
                          },
                        );
                      },
                      backgroundColor: AwColors.appBarColor,
                    ),
                    AwSpacing.s12,
                    WalletButton.textButton(
                      buttonText: 'Volver',
                      onPressed: () => Navigator.of(context).pop(),
                      alignment: MainAxisAlignment.center,
                      colorText: AwColors.blue,
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
}
