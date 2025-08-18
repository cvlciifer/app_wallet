import 'dart:developer';
import 'package:app_wallet/library/main_library.dart';

class LoginProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> loginUser({
    required String email,
    required String password,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final String emailLower = email.toLowerCase();
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: emailLower,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        if (user.emailVerified) {
          onSuccess(); 
        } else {
          await _auth.signOut();
          onError(
              'Debe verificar su correo electrónico antes de iniciar sesión.');
        }
      } else {
        onError('Error al obtener el usuario después del inicio de sesión.');
      }
    } on FirebaseAuthException catch (e) {
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
      onError('Error al iniciar sesión: $e');
    }
  }

  // Método para iniciar sesión con Google
  Future<void> signInWithGoogle({
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        onError('Inicio de sesión cancelado');
        return;
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user != null) {
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          await _createUserProfile(user);
        }
        onSuccess();
      } else {
        onError('Error al obtener el usuario después del inicio de sesión con Google.');
      }
    } on FirebaseAuthException catch (e) {
      onError('Error de autenticación: ${e.message}');
    } catch (e) {
      onError('Error al iniciar sesión con Google: $e');
    }
  }

  // Método privado para crear el perfil del usuario en Firestore
  Future<void> _createUserProfile(User user) async {
    try {
      await _firestore.collection('Registros').doc(user.email).set({
        'email': user.email,
        'username': user.displayName ?? '',
        'token':user.uid,
        'provider': 'google',
        'created_at': FieldValue.serverTimestamp(),
      });
      await _firestore
          .collection('usuarios')
          .doc('Gastos')
          .collection(user.email!.toLowerCase())
          .doc(user.uid)
          .set({});
    } catch (e) {
      log('Error al crear el perfil del usuario: $e');
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      log('Error al cerrar sesión: $e');
    }
  }
}
