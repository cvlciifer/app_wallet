import 'dart:developer';
import 'package:app_wallet/library_section/main_library.dart';

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userEmailKey = 'userEmail';
  static const String _userUidKey = 'userUid';
  static const String _lastUserUidKey = 'lastUserUid';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      final currentUser = _auth.currentUser;

      return isLoggedIn && currentUser != null;
    } catch (e) {
      log('Error verificando estado de login: $e');
      return false;
    }
  }

  Future<void> saveLoginState(String email, {String? uid}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userEmailKey, email);
      if (uid != null) await prefs.setString(_userUidKey, uid);

      if (uid != null) await prefs.setString(_lastUserUidKey, uid);
      log('Estado de login guardado para: $email');
    } catch (e) {
      log('Error guardando estado de login: $e');
    }
  }

  Future<void> clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userUidKey);

      log('Estado de login limpiado');
    } catch (e) {
      log('Error limpiando estado de login: $e');
    }
  }

  Future<void> clearAllLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userUidKey);
      await prefs.remove(_lastUserUidKey);
      log('Estado de login totalmente limpiado');
    } catch (e) {
      log('Error limpiando todo el estado de login: $e');
    }
  }

  Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      log('Error obteniendo email guardado: $e');
      return null;
    }
  }

  Future<String?> getSavedUid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userUidKey);
    } catch (e) {
      log('Error obteniendo uid guardado: $e');
      return null;
    }
  }

  /// Devuelve el último uid con el que el usuario inició sesión en este
  /// dispositivo (persistido incluso tras un signOut). Útil para mostrar
  /// la pantalla de PIN basada en el último usuario conocido.
  Future<String?> getLastSavedUid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastUserUidKey);
    } catch (e) {
      log('Error obteniendo last uid guardado: $e');
      return null;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
