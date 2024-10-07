import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importar este paquete
import 'package:app_wallet/screens/expenses.dart';
import 'package:app_wallet/screens/logIn.dart';
import 'package:app_wallet/screens/filtros.dart';
import 'package:app_wallet/services_bd/register_provider.dart'; // Importa tu provider
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart'; // Importar el provider

var kColorScheme = ColorScheme.fromSeed(
  seedColor: Color.fromARGB(255, 8, 115, 158),
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
          cardTheme: CardTheme(
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
            ThemeMode.light, // Asegúrate de que el modo siempre sea claro
        home: Expenses(),
        routes: {
          '/expense': (ctx) => Expenses(),
          '/logIn': (ctx) => LoginScreen(),
          '/filtros': (ctx) => FiltersScreen(),
        },
      ),
    ),
  );
}
