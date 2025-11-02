import 'dart:developer';
import 'package:app_wallet/library_section/main_library.dart';

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userEmailKey = 'userEmail';

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

  Future<void> saveLoginState(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userEmailKey, email);
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
      log('Estado de login limpiado');
    } catch (e) {
      log('Error limpiando estado de login: $e');
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

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
