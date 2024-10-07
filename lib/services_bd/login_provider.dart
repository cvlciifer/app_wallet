import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      if (userCredential.user != null && userCredential.user!.emailVerified) {
        onSuccess(); // Éxito: correo verificado
      } else {
        // Cerrar la sesión del usuario si no está verificado
        await _auth.signOut();
        onError(
            'Debe verificar su correo electrónico antes de iniciar sesión.');
      }
    } on FirebaseAuthException catch (e) {
      // Manejo de errores de autenticación
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        onError('Usuario o contraseña incorrecta.');
      } else {
        onError(e.message ?? 'Error desconocido al iniciar sesión.');
      }
    } catch (e) {
      // Manejo de errores genéricos
      onError('Error al iniciar sesión: $e');
    }
  }
}
