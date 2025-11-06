import 'package:app_wallet/login_section/presentation/providers/reset_password.dart'
    as local_auth;
import 'package:provider/provider.dart' hide Consumer;
import 'package:app_wallet/library_section/main_library.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide ChangeNotifierProvider;
import 'package:http/http.dart' as http;
import 'dart:convert';

// Endpoint que consume un token de reseteo y puede devolver un custom token de Firebase
const String _consumeResetUrl = String.fromEnvironment(
  'CONSUME_RESET_URL',
  defaultValue: 'https://app-wallet-apis.vercel.app/api/consume-reset',
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

  runApp(ProviderScope(child: AppRoot()));
}

class AppRoot extends StatefulWidget {
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  AppLinks? _appLinks;

  bool _wasBackgrounded = false;
  bool _navigatingToPin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initUniLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasBackgrounded = true;
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (!_wasBackgrounded) return;
      _wasBackgrounded = false;

      if (_navigatingToPin) return;

      try {
        final ctx = _navigatorKey.currentState?.overlay?.context;
        if (ctx != null) {
          final resetState = ProviderScope.containerOf(ctx, listen: false)
              .read(resetFlowProvider);
          if (resetState.status == ResetFlowStatus.allowed) {
            final nav = _navigatorKey.currentState;
            if (nav != null) {
              _navigatingToPin = true;
              nav.pushReplacement(
                MaterialPageRoute(builder: (_) => const SetPinPage()),
              );
              _navigatingToPin = false;
              return;
            }
          }
        }
      } catch (_) {}
      _navigatingToPin = true;

      try {
        final authSvc = AuthService();
        final isLoggedIn = await authSvc.isUserLoggedIn();
        if (!isLoggedIn) return;

        final uid = authSvc.getCurrentUser()?.uid;
        if (uid == null) return;

        final pinService = PinService();
        final hasPin = await pinService.hasPin(accountId: uid);
        if (!hasPin) return;

        final nav = _navigatorKey.currentState;
        if (nav != null) {
          nav.pushReplacement(
            MaterialPageRoute(builder: (_) => EnterPinPage(accountId: uid)),
          );
        }
      } catch (e, st) {
        log('didChangeAppLifecycleState error: $e\n$st');
      } finally {
        _navigatingToPin = false;
      }
    }
  }

  Future<void> _initUniLinks() async {
    try {
      _appLinks = AppLinks();
      final initialUri = await _appLinks!.getInitialAppLink();
      if (initialUri != null) {
        _handleIncomingLink(initialUri.toString());
      }

      try {
        _appLinks!.uriLinkStream.listen((Uri? uri) {
          if (uri != null) _handleIncomingLink(uri.toString());
        });
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _handleIncomingLink(String link) async {
    try {
      final uri = Uri.parse(link);
      final token = uri.queryParameters['token'] ?? uri.queryParameters['link'];
      if (token != null) {
        bool success = false;
        try {
          try {
            final ctx = _navigatorKey.currentState?.overlay?.context;
            if (ctx != null) {
              ProviderScope.containerOf(ctx, listen: false)
                  .read(resetFlowProvider.notifier)
                  .setProcessing();
            }
          } catch (_) {}

          final consumeUrl =
              '$_consumeResetUrl?token=${Uri.encodeQueryComponent(token)}';
          final resp = await http.get(Uri.parse(consumeUrl));
          if (resp.statusCode == 200) {
            final body = jsonDecode(resp.body) as Map<String, dynamic>;
            if (body['success'] == true) {
              final email = body['email'] as String?;

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

                  success = true;
                  try {
                    final ctx = _navigatorKey.currentState?.overlay?.context;
                    if (ctx != null) {
                      ProviderScope.containerOf(ctx, listen: false)
                          .read(resetFlowProvider.notifier)
                          .setAllowed(email);
                    }
                  } catch (_) {}
                } catch (e) {
                  final contextForSnack =
                      (_navigatorKey.currentState?.overlay?.context ?? context)
                          as BuildContext;
                  ScaffoldMessenger.of(contextForSnack).showSnackBar(const SnackBar(
                      content: Text(
                          'No se pudo autenticar con el token proporcionado')));

                  try {
                    final ctx = _navigatorKey.currentState?.overlay?.context;
                    if (ctx != null) {
                      ProviderScope.containerOf(ctx, listen: false)
                          .read(resetFlowProvider.notifier)
                          .clear();
                    }
                  } catch (_) {}
                  return;
                }
              } else {
                success = true;
                try {
                  final ctx = _navigatorKey.currentState?.overlay?.context;
                  if (ctx != null) {
                    ProviderScope.containerOf(ctx, listen: false)
                        .read(resetFlowProvider.notifier)
                        .setAllowed(email);
                  }
                } catch (_) {}
              }

              if (success) {
                _navigatorKey.currentState?.push(
                    MaterialPageRoute(builder: (_) => const SetPinPage()));
              }
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
        } finally {
          if (!success) {
            try {
              final ctx = _navigatorKey.currentState?.overlay?.context;
              if (ctx != null) {
                ProviderScope.containerOf(ctx, listen: false)
                    .read(resetFlowProvider.notifier)
                    .clear();
              }
            } catch (_) {}
          }
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
        builder: (context, child) {
          return Consumer(builder: (ctx, ref, _) {
            final loaderCount = ref.watch(globalLoaderProvider);
            final showLoader = loaderCount > 0;
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (showLoader)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.45),
                      child: const Center(
                        child: WalletLoader(color: AwColors.appBarColor),
                      ),
                    ),
                  ),
              ],
            );
          });
        },
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
