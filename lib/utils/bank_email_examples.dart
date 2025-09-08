import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services_bd/gmail_service.dart';
import '../services_bd/gmail_provider.dart';

/// Ejemplos específicos para correos bancarios
class BankEmailExamples {
  
  /// Lista de bancos chilenos principales
  static final List<Map<String, dynamic>> chileangBanks = [
    {
      'name': 'Banco Santander',
      'domains': ['santander.cl', 'santanderconsumer.cl'],
      'keywords': ['santander', 'banco santander'],
      'color': Colors.red,
    },
    {
      'name': 'Banco de Chile',
      'domains': ['bancochile.cl'],
      'keywords': ['banco de chile', 'edwards'],
      'color': Colors.blue,
    },
    {
      'name': 'BCI',
      'domains': ['bci.cl'],
      'keywords': ['bci', 'banco de credito'],
      'color': Colors.orange,
    },
    {
      'name': 'Banco Estado',
      'domains': ['bancoestado.cl'],
      'keywords': ['banco estado', 'bancoestado'],
      'color': Colors.green,
    },
    {
      'name': 'Scotiabank',
      'domains': ['scotiabank.cl'],
      'keywords': ['scotiabank'],
      'color': Colors.red[800]!,
    },
    {
      'name': 'Banco Itaú',
      'domains': ['itau.cl'],
      'keywords': ['itau', 'corpbanca'],
      'color': Colors.orange[700]!,
    },
    {
      'name': 'Banco Falabella',
      'domains': ['bancofalabella.cl'],
      'keywords': ['falabella', 'banco falabella'],
      'color': Colors.green[800]!,
    },
    {
      'name': 'Banco Ripley',
      'domains': ['ripley.cl'],
      'keywords': ['ripley', 'banco ripley'],
      'color': Colors.purple,
    },
    {
      'name': 'Banco Security',
      'domains': ['bancosecurity.cl'],
      'keywords': ['security'],
      'color': Colors.blue[800]!,
    },
  ];

  /// Tipos de correos bancarios comunes
  static final Map<String, List<String>> emailTypes = {
    'Estados de Cuenta': [
      'estado de cuenta',
      'resumen de cuenta',
      'extracto',
      'cartola',
    ],
    'Transferencias': [
      'transferencia',
      'transfer',
      'envio de dinero',
      'recepcion de dinero',
    ],
    'Pagos': [
      'pago exitoso',
      'pago realizado',
      'confirmacion de pago',
      'comprobante de pago',
    ],
    'Tarjetas': [
      'tarjeta de credito',
      'tarjeta de debito',
      'estado tarjeta',
      'movimientos tarjeta',
    ],
    'Seguridad': [
      'bloqueo',
      'desbloqueo',
      'actividad sospechosa',
      'cambio de clave',
      'acceso no autorizado',
    ],
    'Promociones': [
      'oferta especial',
      'promocion',
      'descuento',
      'beneficio',
    ],
  };

  /// Busca correos por categoría bancaria
  static Future<Map<String, List<EmailInfo>>> searchByBankCategory(
    GmailService gmailService,
  ) async {
    final results = <String, List<EmailInfo>>{};
    
    for (final category in emailTypes.keys) {
      final keywords = emailTypes[category]!;
      final emails = <EmailInfo>[];
      
      for (final keyword in keywords) {
        try {
          final categoryEmails = await gmailService.searchEmailsBySubject(keyword);
          emails.addAll(categoryEmails);
          
          // Pausa para no sobrecargar la API
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint('Error buscando correos de $keyword: $e');
        }
      }
      
      // Remover duplicados y ordenar
      final uniqueEmails = _removeDuplicates(emails);
      uniqueEmails.sort((a, b) => b.date.compareTo(a.date));
      
      results[category] = uniqueEmails;
    }
    
    return results;
  }

  /// Remueve correos duplicados basado en el ID
  static List<EmailInfo> _removeDuplicates(List<EmailInfo> emails) {
    final seen = <String>{};
    return emails.where((email) => seen.add(email.id)).toList();
  }

  /// Identifica el banco de un correo
  static String identifyBank(EmailInfo email) {
    final content = '${email.from} ${email.subject}'.toLowerCase();
    
    for (final bank in chileangBanks) {
      final keywords = bank['keywords'] as List<String>;
      final domains = bank['domains'] as List<String>;
      
      // Verificar por dominio
      for (final domain in domains) {
        if (content.contains(domain)) {
          return bank['name'];
        }
      }
      
      // Verificar por palabras clave
      for (final keyword in keywords) {
        if (content.contains(keyword.toLowerCase())) {
          return bank['name'];
        }
      }
    }
    
    return 'Otro';
  }

  /// Obtiene el color asociado a un banco
  static Color getBankColor(String bankName) {
    final bank = chileangBanks.firstWhere(
      (b) => b['name'] == bankName,
      orElse: () => {'color': Colors.grey},
    );
    return bank['color'] as Color;
  }

  /// Clasifica correos por banco
  static Map<String, List<EmailInfo>> groupEmailsByBank(List<EmailInfo> emails) {
    final grouped = <String, List<EmailInfo>>{};
    
    for (final email in emails) {
      final bank = identifyBank(email);
      grouped.putIfAbsent(bank, () => []).add(email);
    }
    
    // Ordenar cada lista por fecha
    for (final bankEmails in grouped.values) {
      bankEmails.sort((a, b) => b.date.compareTo(a.date));
    }
    
    return grouped;
  }

  /// Estadísticas de correos bancarios
  static Map<String, dynamic> getEmailStats(List<EmailInfo> emails) {
    final bankGroups = groupEmailsByBank(emails);
    final typeStats = <String, int>{};
    
    for (final email in emails) {
      final type = _categorizeEmail(email);
      typeStats[type] = (typeStats[type] ?? 0) + 1;
    }
    
    return {
      'total': emails.length,
      'byBank': bankGroups.map((bank, emails) => MapEntry(bank, emails.length)),
      'byType': typeStats,
      'mostActiveBank': bankGroups.entries
          .reduce((a, b) => a.value.length > b.value.length ? a : b)
          .key,
    };
  }

  /// Categoriza un correo por su tipo
  static String _categorizeEmail(EmailInfo email) {
    final content = '${email.subject} ${email.snippet}'.toLowerCase();
    
    for (final type in emailTypes.keys) {
      final keywords = emailTypes[type]!;
      for (final keyword in keywords) {
        if (content.contains(keyword.toLowerCase())) {
          return type;
        }
      }
    }
    
    return 'Otros';
  }
}

/// Widget de estadísticas bancarias
class BankStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const BankStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas de Correos Bancarios',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Total de correos
            Row(
              children: [
                const Icon(Icons.email, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Total de correos: ${stats['total']}'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Banco más activo
            Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.green),
                const SizedBox(width: 8),
                Text('Banco más activo: ${stats['mostActiveBank']}'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Por banco
            const Text(
              'Por Banco:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...((stats['byBank'] as Map<String, int>).entries.map((entry) {
              final color = BankEmailExamples.getBankColor(entry.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.key)),
                    Text('${entry.value}'),
                  ],
                ),
              );
            })),
            
            const SizedBox(height: 16),
            
            // Por tipo
            const Text(
              'Por Tipo:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...((stats['byType'] as Map<String, int>).entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text('${entry.value}'),
                  ],
                ),
              );
            })),
          ],
        ),
      ),
    );
  }
}

/// Provider para estadísticas de correos bancarios
final bankStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final bankEmails = await ref.watch(bankEmailsProvider.future);
  return BankEmailExamples.getEmailStats(bankEmails);
});
