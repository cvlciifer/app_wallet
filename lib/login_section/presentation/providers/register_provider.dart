import 'package:app_wallet/library_section/main_library.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser({
    required String email,
    required String username,
    required String password,
    required String token,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final String emailLower = email.toLowerCase();

      final bool userExists = await checkUserExist(emailLower);
      if (userExists) {
        onError('El correo electrónico ya está registrado.');
        return;
      }

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailLower,
        password: password,
      );

      await userCredential.user?.sendEmailVerification();

      final String token = userCredential.user?.uid ?? '';

      // Verificar si el usuario ya existía en Registros antes de crear el perfil
      final registroSnapshot =
          await _firestore.collection('Registros').doc(emailLower).get();
      final bool isFirstTimeUser = !registroSnapshot.exists;

      await _firestore.collection('Registros').doc(email).set({
        'email': emailLower,
        'username': username,
        'token': token,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Solo crear el gasto de bienvenida si es la primera vez que se registra el usuario
      if (isFirstTimeUser) {
        await _firestore
            .collection('usuarios')
            .doc(emailLower)
            .collection('gastos')
            .doc(userCredential.user?.uid)
            .set({
          'name': "Bienvenido a AdminWallet",
        });

        await _firestore
            .collection('usuarios')
            .doc(emailLower)
            .collection('ingresos')
            .doc(userCredential.user?.uid)
            .set({
          'name': "Bienvenido a AdminWallet",
        });
      }

      onSuccess();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        onError('Este correo ya está registrado.');
      } else if (e.code == 'weak-password') {
        onError('La contraseña es demasiado débil.');
      } else {
        onError(e.message ?? 'Error desconocido al registrar el usuario.');
      }
    } catch (e) {
      String humanMsg = _humanizeFirebaseError(e);
      onError(humanMsg);
    }
  }

  Future<bool> checkUserExist(String email) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

String _humanizeFirebaseError(Object e) {
  final s = e.toString();

  // Errores de red/conexión
  if (s.contains('I/O error') ||
      s.contains('Connection reset') ||
      s.contains('network') ||
      s.contains('SocketException') ||
      s.contains('HandshakeException')) {
    return 'No se pudo conectar con el servidor. Verifica tu conexión a internet e inténtalo nuevamente.';
  }

  // Timeout
  if (s.contains('timeout') || s.contains('TimeoutException')) {
    return 'La conexión tardó demasiado. Verifica tu conexión e inténtalo nuevamente.';
  }

  // Errores de permisos
  if (s.contains('permission-denied')) {
    return 'No tienes permisos para realizar esta acción.';
  }

  // Error genérico
  return 'Ocurrió un error inesperado. Por favor, inténtalo nuevamente.';
}
