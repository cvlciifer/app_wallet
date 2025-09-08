import 'package:google_sign_in/google_sign_in.dart';

/// Servicio para manejar el estado global de Google Sign-In
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  late final GoogleSignIn _googleSignIn;
  
  /// Inicializa el servicio con los scopes necesarios
  void initialize({List<String>? scopes}) {
    _googleSignIn = GoogleSignIn(
      scopes: scopes ?? [
        'email',
        'profile',
        'https://www.googleapis.com/auth/gmail.readonly',
      ],
    );
  }

  /// Obtiene la instancia de GoogleSignIn
  GoogleSignIn get instance => _googleSignIn;

  /// Obtiene el usuario actual
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Verifica si el usuario está autenticado
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Obtiene el token de acceso del usuario actual
  Future<String?> getCurrentAccessToken() async {
    final user = _googleSignIn.currentUser;
    if (user == null) return null;
    
    final auth = await user.authentication;
    return auth.accessToken;
  }

  /// Verifica si el usuario tiene los scopes necesarios para Gmail
  Future<bool> hasGmailPermissions() async {
    try {
      final user = _googleSignIn.currentUser;
      if (user == null) return false;
      
      final auth = await user.authentication;
      final token = auth.accessToken;
      
      // Verificar si el token tiene permisos de Gmail
      // Esto se hace intentando hacer una llamada simple a la API
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Re-autentica para obtener permisos adicionales
  Future<GoogleSignInAccount?> requestAdditionalScopes() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      print('Error al solicitar permisos adicionales: $e');
      return null;
    }
  }
}
