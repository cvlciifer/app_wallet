import 'dart:developer';
import 'package:app_wallet/library/main_library.dart';
import 'package:app_wallet/services_bd/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app_wallet/service_db_local/create_db.dart';


class LoginProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AuthService _authService = AuthService();

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
          // Guardar estado de login
          await _authService.saveLoginState(emailLower);

          // Asegurar que la DB local exista y crear/actualizar el usuario local
          try {
            // Fuerza inicialización/creación de la BD
            await DBHelper.instance.database;
            // Guarda el uid + correo en la tabla usuarios (upsert)
            await DBHelper.instance.upsertUsuario(uid: user.uid, correo: emailLower);
          } catch (dbErr) {
            log('Error creando/verificando DB local: $dbErr');
            // opcional: enviar onError si quieres detener el login por errores locales
          }

          onSuccess();
        } else {
          await _auth.signOut();
          onError('Debe verificar su correo electrónico antes de iniciar sesión.');
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

        // Guardar estado de login para Google
        final emailLower = (user.email ?? '').toLowerCase();
        await _authService.saveLoginState(emailLower);

        // Asegurar DB local y upsert usuario
        try {
          await DBHelper.instance.database;
          await DBHelper.instance.upsertUsuario(uid: user.uid, correo: emailLower);
        } catch (dbErr) {
          log('Error creando/verificando DB local (Google): $dbErr');
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
      final emailLower = (user.email ?? '').toLowerCase();
      await _firestore.collection('Registros').doc(emailLower).set({
        'email': emailLower,
        'username': user.displayName ?? '',
        'token': user.uid,
        'provider': 'google',
        'created_at': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('usuarios')
          .doc('Gastos')
          .collection(emailLower)
          .doc(user.uid)
          .set({});

      // También almacena localmente (por si es newUser)
      try {
        await DBHelper.instance.database;
        await DBHelper.instance.upsertUsuario(uid: user.uid, correo: emailLower);
      } catch (dbErr) {
        log('Error guardando usuario local tras crear perfil Firestore: $dbErr');
      }
    } catch (e) {
      log('Error al crear el perfil del usuario: $e');
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      // Limpiar estado de login
      await _authService.clearLoginState();
    } catch (e) {
      log('Error al cerrar sesión: $e');
    }
  }
}
