import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services_bd/gmail_service.dart';
import '../services_bd/gmail_provider.dart';

/// Ejemplo de cómo usar el servicio Gmail para buscar correos por asunto
class GmailUsageExample {
  
  /// Ejemplo básico: Buscar correos de confirmación de compra
  static void ejemploBasico() async {
    final gmailService = GmailService();
    
    // 1. Inicializar y autenticar
    final authenticated = await gmailService.initialize();
    
    if (authenticated) {
      // 2. Buscar correos con asunto específico
      final emails = await gmailService.searchEmailsBySubject("Confirmación de compra");
      
      print("Encontrados ${emails.length} correos:");
      for (final email in emails) {
        print("- ${email.subject} de ${email.from}");
      }
    } else {
      print("No se pudo autenticar con Gmail");
    }
  }

  /// Ejemplo con Riverpod provider
  static Widget ejemploConProvider() {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(gmailAuthStateProvider);
        final authNotifier = ref.read(gmailAuthStateProvider.notifier);
        
        return Column(
          children: [
            // Botón para autenticar
            ElevatedButton(
              onPressed: authState.status == GmailAuthStatus.loading 
                ? null 
                : () => authNotifier.authenticate(),
              child: const Text('Conectar Gmail'),
            ),
            
            // Mostrar estado
            if (authState.status == GmailAuthStatus.authenticated)
              const Text('✅ Conectado a Gmail'),
            
            // Buscar correos de facturación
            if (authState.status == GmailAuthStatus.authenticated)
              Consumer(
                builder: (context, ref, child) {
                  final emailsAsync = ref.watch(emailsBySubjectProvider("Factura"));
                  
                  return emailsAsync.when(
                    data: (emails) => Column(
                      children: emails.map((email) => ListTile(
                        title: Text(email.subject),
                        subtitle: Text(email.from),
                        trailing: Text(email.date),
                      )).toList(),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Error: $error'),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  /// Ejemplos de búsquedas específicas por asunto
  static Map<String, String> ejemplosDeAsuntos = {
    'Facturas': 'Factura',
    'Confirmaciones de compra': 'Confirmación de compra',
    'Recibos': 'Recibo',
    'Newsletters': 'Newsletter',
    'Promociones': 'Oferta especial',
    'Avisos bancarios': 'Aviso de movimiento',
    'Suscripciones': 'Suscripción',
    'Pagos': 'Pago exitoso',
    'Transferencias': 'Transferencia',
    'Notificaciones de seguridad': 'Actividad inusual',
  };

  /// Método para buscar múltiples tipos de correos
  static Future<Map<String, List<EmailInfo>>> buscarVariosAsuntos(
    GmailService gmailService,
    List<String> asuntos,
  ) async {
    final resultados = <String, List<EmailInfo>>{};
    
    for (final asunto in asuntos) {
      try {
        final emails = await gmailService.searchEmailsBySubject(asunto);
        resultados[asunto] = emails;
        
        // Pequeña pausa para no sobrecargar la API
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('Error buscando correos con asunto "$asunto": $e');
        resultados[asunto] = [];
      }
    }
    
    return resultados;
  }
}

/// Widget de demostración completa
class GmailDemoWidget extends ConsumerStatefulWidget {
  const GmailDemoWidget({super.key});

  @override
  ConsumerState<GmailDemoWidget> createState() => _GmailDemoWidgetState();
}

class _GmailDemoWidgetState extends ConsumerState<GmailDemoWidget> {
  String selectedSubject = 'Factura';
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(gmailAuthStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Gmail API'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado de autenticación
            _buildAuthSection(authState),
            
            const SizedBox(height: 20),
            
            // Selector de asunto
            if (authState.status == GmailAuthStatus.authenticated) ...[
              const Text('Selecciona un tipo de correo:'),
              DropdownButton<String>(
                value: selectedSubject,
                isExpanded: true,
                items: GmailUsageExample.ejemplosDeAsuntos.entries
                    .map((entry) => DropdownMenuItem(
                          value: entry.value,
                          child: Text('${entry.key} (${entry.value})'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedSubject = value;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 20),
              
              // Lista de correos
              Expanded(
                child: _buildEmailsList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthSection(GmailAuthState authState) {
    final authNotifier = ref.read(gmailAuthStateProvider.notifier);
    
    switch (authState.status) {
      case GmailAuthStatus.initial:
      case GmailAuthStatus.unauthenticated:
        return ElevatedButton.icon(
          onPressed: () => authNotifier.authenticate(),
          icon: const Icon(Icons.login),
          label: const Text('Conectar con Gmail'),
        );
        
      case GmailAuthStatus.loading:
        return const Center(
          child: CircularProgressIndicator(),
        );
        
      case GmailAuthStatus.authenticated:
        return Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Expanded(child: Text('Conectado a Gmail')),
            TextButton(
              onPressed: () => authNotifier.signOut(),
              child: const Text('Desconectar'),
            ),
          ],
        );
        
      case GmailAuthStatus.error:
        return Column(
          children: [
            Text('Error: ${authState.errorMessage}'),
            ElevatedButton(
              onPressed: () => authNotifier.authenticate(),
              child: const Text('Reintentar'),
            ),
          ],
        );
    }
  }

  Widget _buildEmailsList() {
    final emailsAsync = ref.watch(emailsBySubjectProvider(selectedSubject));
    
    return emailsAsync.when(
      data: (emails) {
        if (emails.isEmpty) {
          return Center(
            child: Text('No se encontraron correos con asunto "$selectedSubject"'),
          );
        }
        
        return ListView.builder(
          itemCount: emails.length,
          itemBuilder: (context, index) {
            final email = emails[index];
            return Card(
              child: ListTile(
                title: Text(email.subject),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('De: ${email.from}'),
                    Text('Fecha: ${email.date}'),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Mostrar detalles del correo
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(email.subject),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('De: ${email.from}'),
                            Text('Fecha: ${email.date}'),
                            const SizedBox(height: 16),
                            const Text('Resumen:'),
                            Text(email.snippet),
                            if (email.body.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text('Contenido:'),
                              Text(email.body),
                            ],
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
