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

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailLower,
        password: password,
      );

      await userCredential.user?.sendEmailVerification();

      final String token = userCredential.user?.uid ?? '';

      await _firestore.collection('Registros').doc(email).set({
        'email': emailLower,
        'username': username,
        'token': token,
        'created_at': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('usuarios').doc(emailLower).collection('gastos').doc(userCredential.user?.uid).set({
        'name': "Bienvenido a AdminWallet",
      });

      await _firestore.collection('usuarios').doc(emailLower).collection('ingresos').doc(userCredential.user?.uid).set({
        'name': "Bienvenido a AdminWallet",
      });

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
      onError('Error al registrar el usuario: $e');
    }
  }

  Future<bool> checkUserExist(String email) async {
    try {
      final QuerySnapshot result =
          await _firestore.collection('usuarios').where('email', isEqualTo: email).limit(1).get();
      return result.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
