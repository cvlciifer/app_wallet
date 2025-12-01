import 'package:app_wallet/library_section/main_library.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({Key? key, this.readOnly = false}) : super(key: key);

  final bool readOnly;

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  bool _accepting = false;
  bool _accepted = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accepted_terms', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WalletAppBar(
        title: AwText.bold(
          'Admin Wallet',
          color: AwColors.white,
          size: AwSize.s20,
        ),
        barColor: AwColors.appBarColor,
        showWalletIcon: false,
      ),
      backgroundColor: AwColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TÉRMINOS Y CONDICIONES DE USO',
                        style: TextStyle(
                          fontSize: AwSize.s18,
                          fontWeight: FontWeight.bold,
                          color: AwColors.appBarColor,
                        ),
                      ),
                      AwSpacing.s20,
                      const Text(
                        'Última actualización: 13 de noviembre de 2025',
                        style: TextStyle(fontSize: AwSize.s14),
                      ),
                      AwSpacing.s20,
                      const Text(
                        'Al usar la aplicación móvil AdminWallet (en adelante, “la App”), el usuario acepta los siguientes términos y condiciones. Si no está de acuerdo, no debe utilizarla.',
                      ),
                      AwSpacing.s20,
                      const Text('1. Descripción general', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text(
                          'AdminWallet es una aplicación para Android que permite registrar y gestionar gastos e ingresos personales y recibir consejos financieros básicos. Fue desarrollada por estudiantes universitarios como proyecto académico, sin fines comerciales.'),
                      AwSpacing.s12,
                      const Text('2. Registro y autenticación', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text(
                          """El inicio de sesión se realiza mediante Firebase Authentication (ya sea con cuenta de Google o con correo y contraseña). Las contraseñas son gestionadas exclusivamente por Firebase; los desarrolladores no tienen acceso a ellas.
Al registrarse, no se almacena información personal como correos electrónicos en los servidores de los desarrolladores. Solo se solicita permiso para visualizar en tiempo real los correos dentro de la aplicación, pero dicha información no se envía ni se comparte con el equipo de desarrollo; permanece siempre bajo control del usuario. Además, Firebase genera un token de autenticación y se gestiona un identificador de usuario asociado a la cuenta, necesarios únicamente para el funcionamiento de la app."""),
                      AwSpacing.s12,
                      const Text('3. Datos almacenados', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text(
                          'PIN de acceso: se guarda en el dispositivo y en Firebase de forma hasheada; no puede ser leído por los desarrolladores.'),
                      AwSpacing.s6,
                      const Text(
                          'Gastos e ingresos: se almacenan en Firebase sin hash para permitir sincronización y visualización en la App. Los desarrolladores no usan estos datos con otros fines.'),
                      AwSpacing.s6,
                      const Text(
                          'Importación desde Gmail (OPCIONAL y MANUAL): si el usuario desea, podrá pulsar un botón dentro de la App que inicia explícitamente el proceso de conexión y lectura solo de los correos que el flujo autorizado permita (por ejemplo, mensajes con notificaciones de movimiento de Banco Estado). Esta acción es voluntaria y solo se ejecuta cuando el usuario la solicita. No se importan correos automáticamente; el usuario puede revocar el permiso en cualquier momento. En la importación se extraen los datos necesarios para identificar movimientos (fecha, monto, texto relevante) y no se almacena ni se comparte el correo completo salvo lo necesario para el procesamiento técnico autorizado por el usuario.'),
                      AwSpacing.s12,
                      const Text('4. Consejos financieros', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text(
                          'La App envía un consejo financiero diario de carácter informativo. No constituyen asesoría profesional; los desarrolladores no se responsabilizan por decisiones tomadas en base a ellos.'),
                      AwSpacing.s12,
                      const Text('5. Privacidad y seguridad', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text(
                          'Los datos se alojan en servicios de Firebase (Google), que aplican medidas estándar de seguridad. Los desarrolladores no garantizan seguridad absoluta ni se responsabilizan por accesos no autorizados debidos al mal uso del dispositivo o credenciales compartidas por el usuario.'),
                      AwSpacing.s12,
                      const Text('6. Limitación de responsabilidad', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text(
                          'La App se ofrece “tal cual”. Los desarrolladores no se responsabilizan por pérdidas o daños derivados del uso de la App, errores en sincronización o fallas en la importación de datos.'),
                      AwSpacing.s12,
                      const Text('7. Derechos del usuario', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text(
                          'El usuario puede solicitar la eliminación de sus datos escribiendo a adminwallet.app@gmail.com (o el correo que definan). La App se ajusta a los principios de la Ley N.º 19.628 sobre Protección de la Vida Privada (Chile).'),
                      AwSpacing.s12,
                      const Text('8. Modificaciones', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text(
                          'Estos términos pueden ser modificados; la versión vigente estará disponible en la App.'),
                      AwSpacing.s12,
                      const Text('9. Ley aplicable', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text('Estos términos se rigen por las leyes de la República de Chile.'),
                      AwSpacing.s40,
                      if (!widget.readOnly) ...[
                        Row(
                          children: [
                            Checkbox(
                              value: _accepted,
                              onChanged: (v) => setState(() => _accepted = v ?? false),
                            ),
                            const Expanded(
                              child: Text('Acepto términos y condiciones'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (!widget.readOnly)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: WalletButton.primaryButton(
                        buttonText: 'Continuar',
                        onPressed: (_accepted && !_accepting) ? _accept : null,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
