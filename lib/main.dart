import 'package:app_wallet/login_section/presentation/providers/reset_password.dart'
    as local_auth;
import 'package:provider/provider.dart';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

// Endpoint que consume un token de reseteo y puede devolver un custom token de Firebase
const String _consumeResetUrl = String.fromEnvironment(
  'CONSUME_RESET_URL',
  defaultValue: 'https://admin-wallet-chi.vercel.app/api/consume-reset',
);

var kColorScheme = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 8, 115, 158),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // DEBUG: Imprimir la ubicación de la base de datos
  try {
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, 'adminwallet.db');
    log('UBICACIÓN DE LA BASE DE DATOS: $dbPath');
  } catch (e) {
    log('❌ Error obteniendo ruta de BD: $e');
  }

  // Restringir la orientación a vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation
        .portraitUp, // Solo permitir orientación vertical hacia arriba
  ]);

  runApp(AppRoot());
}

class AppRoot extends StatefulWidget {
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  AppLinks? _appLinks;

  @override
  void initState() {
    super.initState();
    _initUniLinks();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initUniLinks() async {
    try {
      // inicializa AppLinks.
      _appLinks = AppLinks();
      final initialUri = await _appLinks!.getInitialAppLink();
      if (initialUri != null) {
        _handleIncomingLink(initialUri.toString());
      }

      // Escuchar eventos de enlace subsiguientes
      try {
        _appLinks!.uriLinkStream.listen((Uri? uri) {
          if (uri != null) _handleIncomingLink(uri.toString());
        });
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _handleIncomingLink(String link) async {
    try {
      // Nuevo flujo basado en tokens: nuestro hosting redirige con ?token=abcd
      final uri = Uri.parse(link);
      final token = uri.queryParameters['token'] ?? uri.queryParameters['link'];
      if (token != null) {
        try {
          // Llamamos al endpoint consume-reset que consume el token y
          // puede devolver un Firebase customToken para autenticar al usuario.
          final consumeUrl =
              '$_consumeResetUrl?token=${Uri.encodeQueryComponent(token)}';
          final resp = await http.get(Uri.parse(consumeUrl));
          if (resp.statusCode == 200) {
            final body = jsonDecode(resp.body) as Map<String, dynamic>;
            if (body['success'] == true) {
              final storage = const FlutterSecureStorage();
              final email = body['email'] as String?;
              // Guardamos el email para el flujo de SetPin
              if (email != null)
                await storage.write(key: 'pin_reset_email', value: email);

              final customToken = body['customToken'] as String?;
              if (customToken != null && customToken.isNotEmpty) {
                try {
                  await FirebaseAuth.instance
                      .signInWithCustomToken(customToken);
                  try {
                    final authSvc = AuthService();
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    final emailToSave = email ?? '';
                    if (uid != null) {
                      await authSvc.saveLoginState(emailToSave, uid: uid);
                    } else if (emailToSave.isNotEmpty) {
                      await authSvc.saveLoginState(emailToSave);
                    }
                  } catch (_) {}
                } catch (e) {
                  final contextForSnack =
                      (_navigatorKey.currentState?.overlay?.context ?? context)
                          as BuildContext;
                  ScaffoldMessenger.of(contextForSnack).showSnackBar(const SnackBar(
                      content: Text(
                          'No se pudo autenticar con el token proporcionado')));
                  return;
                }
              }

              // Navegar a SetPinPage; si customToken no vino, igualmente permitimos continuar
              _navigatorKey.currentState
                  ?.push(MaterialPageRoute(builder: (_) => const SetPinPage()));
            } else {
              final contextForSnack =
                  (_navigatorKey.currentState?.overlay?.context ?? context)
                      as BuildContext;
              ScaffoldMessenger.of(contextForSnack).showSnackBar(const SnackBar(
                  content: Text('Token inválido o ya consumido')));
            }
          } else {
            final contextForSnack =
                (_navigatorKey.currentState?.overlay?.context ?? context)
                    as BuildContext;
            ScaffoldMessenger.of(contextForSnack).showSnackBar(SnackBar(
                content: Text('Error al consumir token: ${resp.statusCode}')));
          }
        } catch (e) {
          final contextForSnack =
              (_navigatorKey.currentState?.overlay?.context ?? context)
                  as BuildContext;
          ScaffoldMessenger.of(contextForSnack).showSnackBar(const SnackBar(
              content: Text('No se pudo verificar/consumir el token')));
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => RegisterProvider()), // Agrega el RegisterProvider
        ChangeNotifierProvider(
            create: (_) => LoginProvider()), // Agrega también el LoginProvider
        ChangeNotifierProvider(
            create: (_) => local_auth.AuthProvider()), // Agrega el AuthProvider
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData().copyWith(
          useMaterial3: true,
          colorScheme: kColorScheme,
          appBarTheme: AppBarTheme(
            backgroundColor: kColorScheme.onPrimaryContainer,
            foregroundColor: kColorScheme.primaryContainer,
          ),
          cardTheme: CardThemeData(
            color: kColorScheme.secondaryContainer,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kColorScheme.primaryContainer,
            ),
          ),
          textTheme: ThemeData().textTheme.copyWith(
                titleLarge: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kColorScheme.onSecondaryContainer,
                  fontSize: 16,
                ),
              ),
        ),
        themeMode: ThemeMode.light,
        home: const AuthWrapper(),
        routes: {
          '/home-page': (ctx) => const WalletHomePage(),
          '/new-expense': (ctx) => const NewExpenseScreen(),
          '/logIn': (ctx) => LoginScreen(),
          '/filtros': (ctx) => const FiltersScreen(),
          '/forgot-password': (ctx) => ForgotPasswordScreen(),
        },
      ),
    );
  }
}
