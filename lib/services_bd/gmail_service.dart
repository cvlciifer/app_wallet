import 'package:googleapis/gmail/v1.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GmailService {
  static const List<String> _scopes = [
    GmailApi.gmailReadonlyScope,
  ];

  GmailApi? _gmailApi;

  /// Inicializa el servicio de Gmail usando la cuenta ya autenticada
  Future<bool> initializeWithCurrentUser() async {
    try {
      // Obtener la cuenta actual de Google Sign-In (ya autenticada)
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: _scopes);
      final GoogleSignInAccount? currentUser = googleSignIn.currentUser;
      
      GoogleSignInAccount? account;
      
      if (currentUser != null) {
        // Usuario ya autenticado, verificar si tiene los scopes necesarios
        account = currentUser;
        
        // Verificar si necesita re-autenticarse para los nuevos scopes
        try {
          final auth = await account.authentication;
          final client = _GoogleAuthClient(auth.accessToken!);
          _gmailApi = GmailApi(client);
          
          // Probar acceso básico a Gmail
          await _gmailApi!.users.getProfile('me');
          return true;
        } catch (e) {
          // Si falla, necesita re-autenticarse con los nuevos scopes
          print('Necesita re-autenticación para Gmail: $e');
          await googleSignIn.signOut();
        }
      }
      
      // Autenticar con los scopes de Gmail
      account = await googleSignIn.signIn();
      if (account == null) return false;

      final GoogleSignInAuthentication auth = await account.authentication;
      
      final client = _GoogleAuthClient(auth.accessToken!);
      _gmailApi = GmailApi(client);
      
      return true;
    } catch (e) {
      print('Error inicializando Gmail Service: $e');
      return false;
    }
  }

  /// Inicializa el servicio de Gmail con autenticación (método legacy)
  Future<bool> initialize() async {
    return await initializeWithCurrentUser();
  }

  /// Busca correos por asunto específico
  Future<List<EmailInfo>> searchEmailsBySubject(String subject) async {
    if (_gmailApi == null) {
      throw Exception('Gmail API no inicializada. Llama a initialize() primero.');
    }

    try {
      // Buscar mensajes con el asunto específico
      final query = 'subject:"$subject"';
      final response = await _gmailApi!.users.messages.list(
        'me',
        q: query,
        maxResults: 20, // Límite de resultados
      );

      final List<EmailInfo> emails = [];

      if (response.messages != null) {
        for (final message in response.messages!) {
          final emailDetail = await _getEmailDetail(message.id!);
          if (emailDetail != null) {
            emails.add(emailDetail);
          }
        }
      }

      return emails;
    } catch (e) {
      print('Error buscando correos: $e');
      return [];
    }
  }

  /// Busca correos de bancos usando términos comunes
  Future<List<EmailInfo>> searchBankEmails() async {
    if (_gmailApi == null) {
      throw Exception('Gmail API no inicializada. Llama a initialize() primero.');
    }

    try {
      // Lista de términos comunes para correos bancarios
      final bankTerms = [
        'banco',
        'bank',
        'santander',
        'bbva',
        'bci',
        'estado',
        'scotiabank',
        'itau',
        'falabella',
        'ripley',
        'security',
        'consorcio',
        'coopeuch',
        'cuenta',
        'tarjeta',
        'credito',
        'debito',
        'transferencia',
        'movimiento',
        'saldo',
        'estado de cuenta',
        'resumen',
        'extracto',
        'notificacion bancaria'
      ];

      // Crear consulta combinando múltiples términos
      final query = 'from:(${bankTerms.join(' OR ')}) OR subject:(${bankTerms.join(' OR ')})';
      
      final response = await _gmailApi!.users.messages.list(
        'me',
        q: query,
        maxResults: 50, // Más resultados para bancos
      );

      final List<EmailInfo> emails = [];

      if (response.messages != null) {
        for (final message in response.messages!) {
          final emailDetail = await _getEmailDetail(message.id!);
          if (emailDetail != null && _isBankRelated(emailDetail)) {
            emails.add(emailDetail);
          }
          
          // Pequeña pausa para no sobrecargar la API
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Ordenar por fecha (más recientes primero)
      emails.sort((a, b) => b.date.compareTo(a.date));

      return emails;
    } catch (e) {
      print('Error buscando correos de bancos: $e');
      return [];
    }
  }

  /// Verifica si un correo está relacionado con bancos
  bool _isBankRelated(EmailInfo email) {
    final bankKeywords = [
      'banco',
      'bank',
      'santander',
      'bbva',
      'bci',
      'estado',
      'scotiabank',
      'itau',
      'falabella',
      'ripley',
      'security',
      'consorcio',
      'coopeuch',
      'cuenta',
      'tarjeta',
      'credito',
      'debito',
      'transferencia',
      'movimiento',
      'saldo',
      'estado de cuenta',
      'resumen',
      'extracto',
      'notificacion',
      'pago',
      'cobranza',
      'vencimiento',
      'cuota'
    ];

    final searchText = '${email.subject} ${email.from} ${email.snippet}'.toLowerCase();
    
    return bankKeywords.any((keyword) => searchText.contains(keyword.toLowerCase()));
  }

  /// Busca correos de un banco específico
  Future<List<EmailInfo>> searchSpecificBankEmails(String bankName) async {
    if (_gmailApi == null) {
      throw Exception('Gmail API no inicializada. Llama a initialize() primero.');
    }

    try {
      final query = 'from:"$bankName" OR subject:"$bankName"';
      final response = await _gmailApi!.users.messages.list(
        'me',
        q: query,
        maxResults: 30,
      );

      final List<EmailInfo> emails = [];

      if (response.messages != null) {
        for (final message in response.messages!) {
          final emailDetail = await _getEmailDetail(message.id!);
          if (emailDetail != null) {
            emails.add(emailDetail);
          }
        }
      }

      // Ordenar por fecha
      emails.sort((a, b) => b.date.compareTo(a.date));

      return emails;
    } catch (e) {
      print('Error buscando correos del banco $bankName: $e');
      return [];
    }
  }

  /// Obtiene los detalles de un correo específico
  Future<EmailInfo?> _getEmailDetail(String messageId) async {
    try {
      final message = await _gmailApi!.users.messages.get(
        'me',
        messageId,
        format: 'full',
      );

      String subject = '';
      String from = '';
      String date = '';
      String body = '';

      // Extraer headers
      if (message.payload?.headers != null) {
        for (final header in message.payload!.headers!) {
          switch (header.name?.toLowerCase()) {
            case 'subject':
              subject = header.value ?? '';
              break;
            case 'from':
              from = header.value ?? '';
              break;
            case 'date':
              date = header.value ?? '';
              break;
          }
        }
      }

      // Extraer cuerpo del mensaje
      body = _extractEmailBody(message.payload);

      return EmailInfo(
        id: messageId,
        subject: subject,
        from: from,
        date: date,
        body: body,
        snippet: message.snippet ?? '',
      );
    } catch (e) {
      print('Error obteniendo detalles del correo: $e');
      return null;
    }
  }

  /// Extrae el cuerpo del mensaje del payload
  String _extractEmailBody(MessagePart? payload) {
    if (payload == null) return '';

    // Si el payload tiene datos directamente
    if (payload.body?.data != null) {
      return _decodeBase64(payload.body!.data!);
    }

    // Si el payload tiene partes (multipart)
    if (payload.parts != null) {
      for (final part in payload.parts!) {
        if (part.mimeType == 'text/plain' || part.mimeType == 'text/html') {
          if (part.body?.data != null) {
            return _decodeBase64(part.body!.data!);
          }
        }
        // Búsqueda recursiva en partes anidadas
        final nestedBody = _extractEmailBody(part);
        if (nestedBody.isNotEmpty) {
          return nestedBody;
        }
      }
    }

    return '';
  }

  /// Decodifica el contenido base64 del correo
  String _decodeBase64(String encodedData) {
    try {
      // Gmail usa base64url encoding
      String normalized = encodedData.replaceAll('-', '+').replaceAll('_', '/');
      
      // Agregar padding si es necesario
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      
      final bytes = Uri.decodeComponent(normalized);
      return bytes;
    } catch (e) {
      print('Error decodificando base64: $e');
      return '';
    }
  }

  /// Cierra la sesión
  Future<void> signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: _scopes);
    await googleSignIn.signOut();
    _gmailApi = null;
  }

  /// Verifica si el usuario está autenticado
  bool get isAuthenticated => _gmailApi != null;
}

/// Clase para representar la información de un correo
class EmailInfo {
  final String id;
  final String subject;
  final String from;
  final String date;
  final String body;
  final String snippet;

  EmailInfo({
    required this.id,
    required this.subject,
    required this.from,
    required this.date,
    required this.body,
    required this.snippet,
  });

  @override
  String toString() {
    return 'EmailInfo(id: $id, subject: $subject, from: $from, date: $date)';
  }
}

/// Cliente HTTP personalizado para autenticación con Google
class _GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
