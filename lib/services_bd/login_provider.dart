import 'package:app_wallet/library/main_library.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para iniciar sesión, verificando si el correo está verificado
  Future<void> loginUser({
    required String email,
    required String password,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Convertir el email a minúsculas
      final String emailLower = email.toLowerCase();

      // Intentar iniciar sesión
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: emailLower,
        password: password,
      );

      // Verificar si el correo ha sido verificado
      final User? user = userCredential.user;
      if (user != null) {
        if (user.emailVerified) {
          onSuccess(); // Éxito: correo verificado
        } else {
          // Cerrar la sesión del usuario si no está verificado
          await _auth.signOut();
          onError(
              'Debe verificar su correo electrónico antes de iniciar sesión.');
        }
      } else {
        onError('Error al obtener el usuario después del inicio de sesión.');
      }
    } on FirebaseAuthException catch (e) {
      // Manejo de errores de autenticación
      if (e.code == 'user-not-found') {
        onError('No se encontró un usuario con este correo.');
      } else if (e.code == 'wrong-password') {
        onError('Contraseña incorrecta.');
      } else if (e.code == 'too-many-requests') {
        onError('Demasiados intentos fallidos. Por favor, intenta más tarde.');
      } else {
        onError(e.message ?? 'Error desconocido al iniciar sesión.');
      }
    } catch (e) {
      // Manejo de errores genéricos
      onError('Error al iniciar sesión: $e');
    }
  }
}
