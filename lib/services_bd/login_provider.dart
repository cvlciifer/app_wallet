import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
        // El usuario canceló el proceso
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
        // Verificar si es un usuario nuevo y crear su documento en Firestore
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          await _createUserDocument(user);
        }
        onSuccess();
      } else {
        onError('Error al obtener el usuario después del inicio de sesión con Google.');
      }
    } catch (e) {
      onError('Error al iniciar sesión con Google: $e');
      log('Error al iniciar sesión con Google', error: e);
    }
  }

  // Método privado para crear el documento del usuario en Firestore
  Future<void> _createUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'authProvider': 'google',
      });
    } catch (e) {
      print('Error creating user document: $e');
    }
  }
}
