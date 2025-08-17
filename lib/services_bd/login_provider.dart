import 'package:app_wallet/library/main_library.dart';

class LoginProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  // Método para iniciar sesión con Google
  Future<void> signInWithGoogle({
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Iniciar el proceso de autenticación con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        onError('Inicio de sesión cancelado');
        return;
      }

      // Obtener los detalles de autenticación
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Crear las credenciales para Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase con las credenciales de Google
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user != null) {
        // Verificar si es un nuevo usuario y guardarlo en Firestore
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
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'provider': 'google',
      });
    } catch (e) {
      print('Error al crear el perfil del usuario: $e');
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }
}
