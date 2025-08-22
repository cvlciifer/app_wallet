import 'package:app_wallet/services_bd/reset_password.dart' as local_auth;
import 'package:provider/provider.dart';
import 'package:app_wallet/library/main_library.dart';

var kColorScheme = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 8, 115, 158),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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