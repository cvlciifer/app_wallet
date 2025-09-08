import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services_bd/gmail_service.dart';

/// Proveedor del servicio Gmail
final gmailServiceProvider = Provider<GmailService>((ref) {
  return GmailService();
});

/// Estado para la autenticación de Gmail
final gmailAuthStateProvider = StateNotifierProvider<GmailAuthNotifier, GmailAuthState>((ref) {
  final gmailService = ref.watch(gmailServiceProvider);
  return GmailAuthNotifier(gmailService);
});

/// Estados posibles de autenticación
enum GmailAuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Estado de autenticación de Gmail
class GmailAuthState {
  final GmailAuthStatus status;
  final String? errorMessage;

  const GmailAuthState({
    required this.status,
    this.errorMessage,
  });

  GmailAuthState copyWith({
    GmailAuthStatus? status,
    String? errorMessage,
  }) {
    return GmailAuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

/// Notificador para manejar el estado de autenticación
class GmailAuthNotifier extends StateNotifier<GmailAuthState> {
  final GmailService _gmailService;

  GmailAuthNotifier(this._gmailService) 
    : super(const GmailAuthState(status: GmailAuthStatus.initial));

  /// Inicializa y autentica con Gmail
  Future<void> authenticate() async {
    state = state.copyWith(status: GmailAuthStatus.loading);
    
    try {
      final success = await _gmailService.initialize();
      
      if (success) {
        state = state.copyWith(status: GmailAuthStatus.authenticated);
      } else {
        state = state.copyWith(
          status: GmailAuthStatus.unauthenticated,
          errorMessage: 'No se pudo autenticar con Gmail',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: GmailAuthStatus.error,
        errorMessage: 'Error durante la autenticación: $e',
      );
    }
  }

  /// Cierra la sesión de Gmail
  Future<void> signOut() async {
    try {
      await _gmailService.signOut();
      state = state.copyWith(status: GmailAuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: GmailAuthStatus.error,
        errorMessage: 'Error al cerrar sesión: $e',
      );
    }
  }
}

/// Proveedor para buscar correos por asunto
final emailsBySubjectProvider = FutureProvider.family<List<EmailInfo>, String>((ref, subject) async {
  final gmailService = ref.watch(gmailServiceProvider);
  final authState = ref.watch(gmailAuthStateProvider);
  
  if (authState.status != GmailAuthStatus.authenticated) {
    throw Exception('No está autenticado con Gmail');
  }
  
  return await gmailService.searchEmailsBySubject(subject);
});

/// Proveedor para buscar correos bancarios
final bankEmailsProvider = FutureProvider<List<EmailInfo>>((ref) async {
  final gmailService = ref.watch(gmailServiceProvider);
  final authState = ref.watch(gmailAuthStateProvider);
  
  if (authState.status != GmailAuthStatus.authenticated) {
    throw Exception('No está autenticado con Gmail');
  }
  
  return await gmailService.searchBankEmails();
});

/// Proveedor para buscar correos de un banco específico
final specificBankEmailsProvider = FutureProvider.family<List<EmailInfo>, String>((ref, bankName) async {
  final gmailService = ref.watch(gmailServiceProvider);
  final authState = ref.watch(gmailAuthStateProvider);
  
  if (authState.status != GmailAuthStatus.authenticated) {
    throw Exception('No está autenticado con Gmail');
  }
  
  return await gmailService.searchSpecificBankEmails(bankName);
});
