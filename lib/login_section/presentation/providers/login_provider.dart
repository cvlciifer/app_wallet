import 'dart:developer';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:sqflite/sqflite.dart';

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
          // Guardar estado de login (incluye uid)
          await _authService.saveLoginState(emailLower, uid: user.uid);

          try {
            await DBHelper.instance.database;

            // Verificar si el usuario ya existe en la BD local
            final existingUser =
                await DBHelper.instance.getUsuarioPorUid(user.uid);

            if (existingUser != null) {
              log('Usuario encontrado en BD local: ${existingUser['correo']}');
              if (existingUser['correo'] != emailLower) {
                log('Email actualizado de ${existingUser['correo']} a $emailLower');
                await DBHelper.instance
                    .upsertUsuario(uid: user.uid, correo: emailLower);
              }
            } else {
              log('Usuario nuevo, guardando en BD local: $emailLower');
              // Usuario nuevo, guardarlo
              await DBHelper.instance
                  .upsertUsuario(uid: user.uid, correo: emailLower);
            }
          } catch (dbErr) {
            log('Error creando/verificando DB local: $dbErr');
          }

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
      String humanMsg = _humanizeFirebaseError(e);
      onError(humanMsg);
    }
  }

  Future<void> signInWithGoogle({
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      await _googleSignIn.signOut();
      final dbPath = await getDatabasesPath();
      log('Ruta de la base de datos: $dbPath/adminwallet.db');

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

        // Guardar estado de login para Google (incluye uid)
        final emailLower = (user.email ?? '').toLowerCase();
        await _authService.saveLoginState(emailLower, uid: user.uid);

        try {
          await DBHelper.instance.database;

          // Verificar si el usuario ya existe en la BD local
          final existingUser =
              await DBHelper.instance.getUsuarioPorUid(user.uid);

          if (existingUser != null) {
            log('Usuario Google encontrado en BD local: ${existingUser['correo']}');
            if (existingUser['correo'] != emailLower) {
              log('Email Google actualizado de ${existingUser['correo']} a $emailLower');
              await DBHelper.instance
                  .upsertUsuario(uid: user.uid, correo: emailLower);
            }
          } else {
            log('Usuario Google nuevo, guardando en BD local: $emailLower');
            await DBHelper.instance
                .upsertUsuario(uid: user.uid, correo: emailLower);
          }
        } catch (dbErr) {
          log('Error creando/verificando DB local (Google): $dbErr');
        }

        onSuccess();
      } else {
        onError(
            'Error al obtener el usuario después del inicio de sesión con Google.');
      }
    } on FirebaseAuthException catch (e) {
      String humanMsg = _humanizeFirebaseError(e);
      onError(humanMsg);
    } catch (e) {
      String humanMsg = _humanizeGoogleSignInError(e);
      onError(humanMsg);
    }
  }

  Future<void> _createUserProfile(User user) async {
    try {
      final emailLower = (user.email ?? '').toLowerCase();

      // Verificar si el usuario ya existía en Registros antes de crear el perfil
      final registroSnapshot =
          await _firestore.collection('Registros').doc(emailLower).get();
      final bool isFirstTimeUser = !registroSnapshot.exists;

      await _firestore.collection('Registros').doc(emailLower).set({
        'email': emailLower,
        'username': user.displayName ?? '',
        'token': user.uid,
        'provider': 'google',
        'created_at': FieldValue.serverTimestamp(),
      });

      // Solo crear el gasto de bienvenida si es la primera vez que se registra el usuario
      if (isFirstTimeUser) {
        await _firestore
            .collection('usuarios')
            .doc(emailLower)
            .collection('gastos')
            .doc(user.uid)
            .set({
          'name': "Bienvenido a AdminWallet",
        });

        await _firestore
            .collection('usuarios')
            .doc(emailLower)
            .collection('ingresos')
            .doc(user.uid)
            .set({
          'name': "Bienvenido a AdminWallet",
        });
      }

      try {
        await DBHelper.instance.database;
        await DBHelper.instance
            .upsertUsuario(uid: user.uid, correo: emailLower);
      } catch (dbErr) {
        log('Error guardando usuario local tras crear perfil Firestore: $dbErr');
      }
    } catch (e) {
      log('Error al crear el perfil del usuario: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      await _authService.clearLoginState();
    } catch (e) {
      log('Error al cerrar sesión: $e');
    }
  }
}

String _humanizeGoogleSignInError(Object e) {
  final s = e.toString();

  if (s.contains('ApiException: 7') || s.contains('network_error')) {
    return 'No se pudo conectar con Google. Verifica tu conexión a internet e inténtalo nuevamente.';
  }

  if (e is PlatformException) {
    final code = e.code;
    if (code.contains('network_error')) {
      return 'Hubo un problema de red al conectar con Google. Revisa tu conexión e inténtalo otra vez.';
    }
  }

  return 'No se pudo iniciar sesión con Google. Inténtalo nuevamente.';
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
