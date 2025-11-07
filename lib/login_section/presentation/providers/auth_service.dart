import 'dart:developer';
import 'package:app_wallet/library_section/main_library.dart';

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userEmailKey = 'userEmail';
  static const String _userUidKey = 'userUid';
  static const String _lastUserUidKey = 'lastUserUid';
  static const String _rememberSessionKey = 'rememberSession';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> isUserLoggedIn() async {
    try {
      // Rely primarily on FirebaseAuth's currentUser for session persistence.
      // SharedPreferences flags are advisory, but FirebaseAuth is the source of truth.
      final currentUser = _auth.currentUser;
      return currentUser != null;
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
      await prefs.setBool(_rememberSessionKey, true);
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
      await prefs.remove(_rememberSessionKey);
      log('Estado de login totalmente limpiado');
    } catch (e) {
      log('Error limpiando todo el estado de login: $e');
    }
  }

  Future<void> setRememberSessionFlag(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberSessionKey, value);
    } catch (e) {
      log('Error guardando flag rememberSession: $e');
    }
  }

  Future<bool> getRememberSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberSessionKey) ?? false;
    } catch (e) {
      log('Error leyendo flag rememberSession: $e');
      return false;
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
