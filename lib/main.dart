import 'package:app_wallet/services_bd/reset_password.dart' as local_auth;
import 'package:provider/provider.dart';
import 'package:app_wallet/library/main_library.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => RegisterProvider()), // Agrega el RegisterProvider
        ChangeNotifierProvider(
            create: (_) => LoginProvider()), // Agrega también el LoginProvider
        ChangeNotifierProvider(
            create: (_) => local_auth.AuthProvider()), // Agrega el AuthProvider
      ],
      child: MaterialApp(
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
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
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
        themeMode:
            ThemeMode.light, 
        home: const AuthWrapper(), 
        routes: {
          '/home-page': (ctx) => const WalletHomePage(),
          '/new-expense': (ctx) => const NewExpenseScreen(),
          '/logIn': (ctx) =>  LoginScreen(),
          '/filtros': (ctx) => const FiltersScreen(),
          '/forgot-password': (ctx) =>
              ForgotPasswordScreen(), 
        },
      ),
    ),
  );
}