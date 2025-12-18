import 'package:app_wallet/login_section/presentation/providers/reset_password.dart'
    as local_auth;
import 'package:provider/provider.dart' hide Consumer;
import 'package:app_wallet/library_section/main_library.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod
    hide ChangeNotifierProvider;
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';

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
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await remoteConfig.fetchAndActivate();
    log('Remote Config inicializado');
  } catch (e) {
    log('Error inicializando Remote Config: $e');
  }

  try {
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, 'adminwallet.db');
    log('UBICACIÓN DE LA BASE DE DATOS: $dbPath');
  } catch (e) {
    log('Error obteniendo ruta de BD: $e');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  try {
    await initializeDateFormatting('es');
  } catch (_) {}

  try {
    await ZoomService().init();
  } catch (_) {}

  runApp(riverpod.ProviderScope(child: AppRoot()));
}

class AppRoot extends StatefulWidget {
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  AppLinks? _appLinks;

  DateTime? _backgroundedAt;
  bool _navigatingToPin = false;
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initUniLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      (() async {
        try {
          await ZoomService().init();
        } catch (_) {}

        final bool? zoomState = ZoomService().isZoomed.value;
        log('ZoomService.isZoomed after init: $zoomState');

        final BuildContext ctx =
            _navigatorKey.currentState?.overlay?.context ?? this.context;

        if (zoomState == true) {
          try {
            await Future.delayed(const Duration(milliseconds: 700));
            await WalletPopup.showNotificationWarningOrange(
              context: ctx,
              message:
                  'Detectamos que el zoom del sistema está activo. Algunas pantallas serán scrollables.',
              visibleTime: 0,
              isDismissible: true,
            );
          } catch (_) {}
          return;
        }

        try {
          await _maybeNavigateToPinOnStartup();
        } catch (_) {}
        try {
          await _maybeShowZoomDialog();
        } catch (_) {}
      })();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    log('App lifecycle event: $state (previous: $_lastLifecycleState)');

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_lastLifecycleState == AppLifecycleState.resumed ||
          _backgroundedAt == null) {
        _backgroundedAt = DateTime.now();
        log('Recorded background time: $_backgroundedAt');
      } else {
        log('Background event ignored; last state=$_lastLifecycleState, backgroundedAt=$_backgroundedAt');
      }
      _lastLifecycleState = state;
      return;
    }

    if (state == AppLifecycleState.resumed) {
      log('Resumed; background timestamp was: $_backgroundedAt');
      Future(() async {
        try {
          await ZoomService().init();
          await _maybeShowZoomDialog();
        } catch (_) {}
      });
      if (_backgroundedAt == null) {
        log('No background timestamp — skipping PIN check');
        return;
      }
      final elapsed = DateTime.now().difference(_backgroundedAt!);
      log('Elapsed while backgrounded: ${elapsed.inSeconds}s');
      _backgroundedAt = null;
      _lastLifecycleState = state;
      if (elapsed.inSeconds < 30) {
        log('Background < 30s — skipping PIN navigation');
        return;
      }
      log('Background >= 30s — proceeding to PIN checks');

      if (_navigatingToPin) return;

      try {
        final ctx = _navigatorKey.currentState?.overlay?.context;
        if (ctx != null) {
          final resetState =
              riverpod.ProviderScope.containerOf(ctx, listen: false)
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
        String? uid = authSvc.getCurrentUser()?.uid;
        if (uid == null) {
          final remember = await authSvc.getRememberSession();
          if (!remember) return;

          uid = await authSvc.getSavedUid() ?? await authSvc.getLastSavedUid();
          if (uid == null) return;
        }

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

  Future<void> _maybeNavigateToPinOnStartup() async {
    if (_navigatingToPin) return;
    _navigatingToPin = true;
    try {
      final authSvc = AuthService();
      String? uid = authSvc.getCurrentUser()?.uid;
      if (uid == null) {
        final remember = await authSvc.getRememberSession();
        if (!remember) return;
        uid = await authSvc.getSavedUid() ?? await authSvc.getLastSavedUid();
        if (uid == null) return;
      }

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
      log('startup PIN navigation error: $e\n$st');
    } finally {
      _navigatingToPin = false;
    }
  }

  Future<void> _maybeShowZoomDialog() async {
    try {
      final notifier = ZoomService().isZoomed;
      bool? val = notifier.value;

      if (val == null) {
        final completer = Completer<bool?>();
        void listener() {
          final v = notifier.value;
          if (v != null) {
            notifier.removeListener(listener);
            completer.complete(v);
          }
        }

        notifier.addListener(listener);
        try {
          val = await completer.future.timeout(const Duration(seconds: 2));
        } catch (_) {
          try {
            notifier.removeListener(listener);
          } catch (_) {}
        }
      }

      final BuildContext ctx =
          _navigatorKey.currentState?.overlay?.context ?? this.context;

      bool zoomDetected = val == true;
      if (!zoomDetected) {
        try {
          final t = MediaQuery.of(ctx).textScaleFactor;
          if (t >= 1.15) zoomDetected = true;
        } catch (_) {}
      }

      if (!zoomDetected) {
        try {
          await ZoomDialogService().markSeenFor(false);
        } catch (_) {}
        return;
      }

      try {
        final seen = await ZoomDialogService().hasSeenDialogFor(true);
        if (seen) return;
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 700));

      await WalletPopup.showNotificationWarningOrange(
        context: ctx,
        message:
            'Detectamos que el zoom del sistema está activo. Algunas pantallas serán scrollables.',
        visibleTime: 0,
        isDismissible: true,
      );

      try {
        await ZoomDialogService().markSeenFor(true);
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _handleIncomingLink(String link) async {
    try {
      final uri = Uri.parse(link);
      final token = uri.queryParameters['token'] ?? uri.queryParameters['link'];
      if (token != null) {
        bool success = false;
        final ctxForLoader = _navigatorKey.currentState?.overlay?.context;
        if (ctxForLoader != null) {
          try {
            riverpod.ProviderScope.containerOf(ctxForLoader, listen: false)
                .read(globalLoaderProvider.notifier)
                .state = true;
          } catch (_) {}
        }

        try {
          try {
            final ctx = _navigatorKey.currentState?.overlay?.context;
            if (ctx != null) {
              riverpod.ProviderScope.containerOf(ctx, listen: false)
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
                      riverpod.ProviderScope.containerOf(ctx, listen: false)
                          .read(resetFlowProvider.notifier)
                          .setAllowed(email);
                    }
                  } catch (_) {}
                } catch (e) {
                  // Authentication with custom token failed — user alert removed per UX decision.

                  try {
                    final ctx = _navigatorKey.currentState?.overlay?.context;
                    if (ctx != null) {
                      riverpod.ProviderScope.containerOf(ctx, listen: false)
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
                    riverpod.ProviderScope.containerOf(ctx, listen: false)
                        .read(resetFlowProvider.notifier)
                        .setAllowed(email);
                  }
                } catch (_) {}
              }

              if (success) {
                _navigatorKey.currentState?.push(
                    MaterialPageRoute(builder: (_) => const SetPinPage()));
              }
            }
          } else {}
        } catch (e) {
          // exception while consuming token; will show a consolidated popup below
        } finally {
          if (!success) {
            try {
              final ctx = _navigatorKey.currentState?.overlay?.context;
              if (ctx != null) {
                riverpod.ProviderScope.containerOf(ctx, listen: false)
                    .read(resetFlowProvider.notifier)
                    .clear();
              }
            } catch (_) {}
            try {
              final popupCtx = (_navigatorKey.currentState?.overlay?.context ??
                  context) as BuildContext;
              WalletPopup.showNotificationError(
                  context: popupCtx, title: 'Token inválido o ya consumido');
            } catch (_) {}
          }

          if (ctxForLoader != null) {
            try {
              riverpod.ProviderScope.containerOf(ctxForLoader, listen: false)
                  .read(globalLoaderProvider.notifier)
                  .state = false;
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
        ChangeNotifierProvider(create: (_) => WalletExpensesController()),
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),
        ChangeNotifierProvider(create: (_) => RegisterProvider()),
        ChangeNotifierProvider(create: (_) => AliasProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => local_auth.AuthProvider()),
      ],
      child: MaterialApp(
        builder: (context, child) {
          const double kMinTextScale = 1;
          const double kMaxTextScale = 1.5;
          final mq = MediaQuery.of(context);
          // ignore: deprecated_member_use
          double clampedScale = mq.textScaleFactor;
          try {
            clampedScale =
                // ignore: deprecated_member_use
                mq.textScaleFactor.clamp(kMinTextScale, kMaxTextScale);
          } catch (_) {}

          // ignore: deprecated_member_use
          final media = mq.copyWith(textScaleFactor: clampedScale);

          return MediaQuery(
            data: media,
            child: riverpod.Consumer(builder: (ctx, ref, _) {
              final showLoader = ref.watch(globalLoaderProvider);
              return Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  if (showLoader)
                    Positioned.fill(
                      child: Container(
                        // ignore: deprecated_member_use
                        color: AwColors.black.withOpacity(0.45),
                        child: const Center(
                          child: WalletLoader(),
                        ),
                      ),
                    ),
                ],
              );
            }),
          );
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
        home: const WelcomeScreen(),
        routes: {
          '/home-page': (ctx) => const WalletHomePage(),
          '/new-expense': (ctx) => const NewExpenseScreen(),
          '/logIn': (ctx) => const LoginScreen(),
          '/forgot-password': (ctx) => ForgotPasswordScreen(),
        },
      ),
    );
  }
}
