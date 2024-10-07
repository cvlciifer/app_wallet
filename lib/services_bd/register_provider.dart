import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para registrar un nuevo usuario
  Future<void> registerUser({
    required String email,
    required String username,
    required String password,
    required String token,
    required Function onSuccess, // Método de éxito opcional
    required Function(String) onError,
  }) async {
    try {
      // Convertir el email a minúsculas
      final String emailLower = email.toLowerCase();

      // Verificar si el email ya existe en la base de datos
      final bool userExists = await checkUserExist(emailLower);
      if (userExists) {
        onError('El correo electrónico ya está registrado.');
        return;
      }

      // Crear el nuevo usuario con Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailLower,
        password: password,
      );

      // Enviar correo de verificación
      await userCredential.user?.sendEmailVerification();
      // Obtener el UID del usuario
      final String token = userCredential.user?.uid ?? '';

      // Almacenar la información adicional del usuario en Firestore
      await _firestore.collection('Registros').doc(email).set({
        'email': emailLower,
        'username': username,
        'token': token,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Crear una colección con el nombre del email en minúsculas dentro del documento del usuario
      await _firestore
          .collection('usuarios')
          .doc('Gastos')
          .collection(emailLower) // Cambiar a emailLower
          .doc(userCredential.user?.uid)
          .set({
        'email': emailLower,
        'username': username,
        'token': token,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Llamar al método de éxito
      onSuccess();
    } on FirebaseAuthException catch (e) {
      // Manejar errores de autenticación
      if (e.code == 'email-already-in-use') {
        onError('Este correo ya está registrado.');
      } else if (e.code == 'weak-password') {
        onError('La contraseña es demasiado débil.');
      } else {
        onError(e.message ?? 'Error desconocido al registrar el usuario.');
      }
    } catch (e) {
      // Manejo de errores genéricos
      onError('Error al registrar el usuario: $e');
    }
  }

  // Método para verificar si el usuario ya existe en la base de datos
  Future<bool> checkUserExist(String email) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      // Si ocurre un error, considera que no existe el usuario
      return false;
    }
  }
}
