import 'package:app_wallet/library/main_library.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Método para restablecer la contraseña
  Future<void> resetPassword(
      String email, Function onSuccess, Function(String) onError) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      onSuccess();
    } on FirebaseAuthException catch (e) {
      onError(e.message ?? 'Error desconocido al restablecer la contraseña.');
    } catch (e) {
      onError('Error al restablecer la contraseña: $e');
    }
  }
}
