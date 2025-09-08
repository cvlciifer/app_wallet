import 'dart:developer';
import '../models/expense.dart';
import '../models/category.dart';
import '../services_bd/gmail_service.dart';

/// Servicio para extraer información financiera de correos bancarios
class BankEmailParser {
  
  /// Extrae información financiera de un correo
  static BankTransactionInfo? parseEmailContent(EmailInfo email) {
    final content = '${email.subject} ${email.body} ${email.snippet}'.toLowerCase();
    
    // Extraer monto
    final amount = _extractAmount(content);
    if (amount == null) return null;
    
    // Extraer tipo de transacción
    final transactionType = _extractTransactionType(content);
    
    // Extraer descripción/comercio
    final description = _extractDescription(content, email.subject);
    
    // Extraer fecha (usar fecha del email como fallback)
    final date = _extractDate(email.date, content);
    
    // Determinar si es ingreso o gasto
    final isIncome = _isIncome(content, transactionType);
    
    // Identificar banco
    final bank = _identifyBank(email.from);
    
    return BankTransactionInfo(
      amount: amount,
      transactionType: transactionType,
      merchantOrDescription: description,
      date: date,
      isIncome: isIncome,
      bank: bank,
      originalEmail: email,
    );
  }
  
  /// Extrae el monto de la transacción del contenido del correo
  static double? _extractAmount(String content) {
    // Patrones para diferentes formatos de montos chilenos
    final List<RegExp> patterns = [
      // Formato: $1.234.567
      RegExp(r'\$\s?(\d{1,3}(?:\.\d{3})*)', caseSensitive: false),
      // Formato: CLP 1.234.567
      RegExp(r'clp\s+(\d{1,3}(?:\.\d{3})*)', caseSensitive: false),
      // Formato: 1.234.567 pesos
      RegExp(r'(\d{1,3}(?:\.\d{3})*)\s*pesos?', caseSensitive: false),
      // Formato: monto: 1.234.567
      RegExp(r'monto[:=]\s*\$?\s*(\d{1,3}(?:\.\d{3})*)', caseSensitive: false),
      // Formato: valor: $1.234.567
      RegExp(r'valor[:=]\s*\$?\s*(\d{1,3}(?:\.\d{3})*)', caseSensitive: false),
      // Formato: por $1.234.567
      RegExp(r'por\s+\$\s*(\d{1,3}(?:\.\d{3})*)', caseSensitive: false),
      // Formato: total $1.234.567
      RegExp(r'total\s+\$\s*(\d{1,3}(?:\.\d{3})*)', caseSensitive: false),
      // Formato con comas como separador de miles: $1,234,567
      RegExp(r'\$\s?(\d{1,3}(?:,\d{3})*)', caseSensitive: false),
      // Formato: números con puntos como separadores
      RegExp(r'(\d{1,3}(?:\.\d{3})+)(?!\d)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        try {
          String amountStr = match.group(1)!;
          // Remover puntos y comas que son separadores de miles
          amountStr = amountStr.replaceAll('.', '').replaceAll(',', '');
          final amount = double.parse(amountStr);
          
          // Validar que el monto sea razonable (entre $100 y $100,000,000)
          if (amount >= 100 && amount <= 100000000) {
            log('Monto extraído: $amount');
            return amount;
          }
        } catch (e) {
          log('Error parsing amount: $e');
          continue;
        }
      }
    }
    
    return null;
  }
  
  /// Extrae el tipo de transacción del contenido
  static String _extractTransactionType(String content) {
    final Map<String, List<String>> transactionTypes = {
      'Transferencia': ['transferencia', 'transfer', 'envío', 'envio'],
      'Compra': ['compra', 'purchase', 'pago', 'payment'],
      'Retiro': ['retiro', 'withdrawal', 'cajero', 'atm'],
      'Depósito': ['depósito', 'deposito', 'deposit', 'abono'],
      'Débito': ['débito', 'debito', 'debit', 'cargo'],
      'Crédito': ['crédito', 'credito', 'credit'],
      'Recarga': ['recarga', 'carga', 'top-up'],
      'Suscripción': ['suscripción', 'suscripcion', 'subscription'],
    };
    
    for (final entry in transactionTypes.entries) {
      for (final keyword in entry.value) {
        if (content.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    return 'Transacción';
  }
  
  /// Extrae la descripción o nombre del comercio
  static String _extractDescription(String content, String subject) {
    // Patrones para extraer información del comercio o descripción
    final List<RegExp> patterns = [
      // En [comercio] o comercio:
      RegExp(r'en\s+([^,\n]+?)(?:\s|,|$)', caseSensitive: false),
      RegExp(r'([a-zA-Z\s]+):', caseSensitive: false),
      // Después de "compra en" o "pago en"
      RegExp(r'(?:compra|pago)\s+en\s+([^,\n]+)', caseSensitive: false),
      // Comercio entre comillas o paréntesis
      RegExp(r'"([^"]+)"', caseSensitive: false),
      RegExp(r"'([^']+)'", caseSensitive: false),
      RegExp(r'\(([^)]+)\)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        String description = match.group(1)?.trim() ?? '';
        if (description.length > 3 && description.length < 100) {
          return _capitalizeWords(description);
        }
      }
    }
    
    // Si no se encuentra descripción específica, usar parte del subject
    String cleanSubject = subject.replaceAll(RegExp(r'(re:|fw:|fwd:)', caseSensitive: false), '').trim();
    if (cleanSubject.length > 10) {
      return _capitalizeWords(cleanSubject.substring(0, 50));
    }
    
    return 'Transacción bancaria';
  }
  
  /// Capitaliza las palabras de un texto
  static String _capitalizeWords(String text) {
    return text.split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase() 
            : word)
        .join(' ');
  }
  
  /// Extrae la fecha de la transacción
  static DateTime _extractDate(String emailDate, String content) {
    // Patrones para fechas en español
    final List<RegExp> datePatterns = [
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})', caseSensitive: false),
      RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})', caseSensitive: false),
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})', caseSensitive: false),
    ];
    
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        try {
          int day, month, year;
          
          // Determinar formato basado en la longitud del primer grupo
          if (match.group(1)!.length == 4) {
            // Formato YYYY-MM-DD
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
          } else {
            // Formato DD/MM/YYYY o DD-MM-YYYY
            day = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);
          }
          
          final extractedDate = DateTime(year, month, day);
          
          // Validar que la fecha sea razonable (últimos 2 años o próximos 30 días)
          final now = DateTime.now();
          final twoYearsAgo = now.subtract(const Duration(days: 730));
          final thirtyDaysFromNow = now.add(const Duration(days: 30));
          
          if (extractedDate.isAfter(twoYearsAgo) && extractedDate.isBefore(thirtyDaysFromNow)) {
            return extractedDate;
          }
        } catch (e) {
          log('Error parsing date: $e');
          continue;
        }
      }
    }
    
    // Fallback a la fecha del email
    try {
      return DateTime.parse(emailDate);
    } catch (e) {
      log('Error parsing email date: $e');
      return DateTime.now();
    }
  }
  
  /// Determina si es un ingreso o gasto basado en el contenido
  static bool _isIncome(String content, String transactionType) {
    final List<String> incomeKeywords = [
      'depósito', 'deposito', 'deposit', 'abono', 'ingreso', 'recibido',
      'transferencia recibida', 'crédito', 'credito', 'reembolso'
    ];
    
    final List<String> expenseKeywords = [
      'compra', 'pago', 'retiro', 'débito', 'debito', 'cargo', 'gasto',
      'transferencia enviada', 'suscripción', 'suscripcion'
    ];
    
    // Verificar palabras clave de ingreso
    for (final keyword in incomeKeywords) {
      if (content.contains(keyword)) {
        return true;
      }
    }
    
    // Verificar palabras clave de gasto
    for (final keyword in expenseKeywords) {
      if (content.contains(keyword)) {
        return false;
      }
    }
    
    // Por defecto, asumir que es un gasto
    return false;
  }
  
  /// Identifica el banco basado en el remitente
  static String _identifyBank(String from) {
    final Map<String, List<String>> bankIdentifiers = {
      'Banco de Chile': ['bancochile', 'banco-chile', 'bancodechile'],
      'BCI': ['bci', 'banco-bci'],
      'Santander': ['santander', 'banco-santander'],
      'Falabella': ['falabella', 'banco-falabella', 'cmr'],
      'Estado': ['bancoestado', 'banco-estado'],
      'Scotiabank': ['scotiabank', 'scotia'],
      'Itaú': ['itau', 'banco-itau'],
      'Security': ['security', 'banco-security'],
      'Ripley': ['ripley', 'banco-ripley'],
      'BBVA': ['bbva'],
      'Consorcio': ['consorcio'],
    };
    
    final fromLower = from.toLowerCase();
    
    for (final entry in bankIdentifiers.entries) {
      for (final identifier in entry.value) {
        if (fromLower.contains(identifier)) {
          return entry.key;
        }
      }
    }
    
    return 'Banco desconocido';
  }
  
  /// Convierte la información de transacción a un objeto Expense
  static Expense convertToExpense(BankTransactionInfo transaction) {
    return Expense(
      title: '${transaction.bank}: ${transaction.transactionType}',
      amount: transaction.amount,
      date: transaction.date,
      category: _determineCategory(transaction.transactionType, transaction.merchantOrDescription),
    );
  }
  
  /// Determina la categoría apropiada basada en el tipo de transacción y descripción
  static Category _determineCategory(String transactionType, String description) {
    final descriptionLower = description.toLowerCase();
    
    // Mapeo de palabras clave a categorías existentes
    final Map<Category, List<String>> categoryKeywords = {
      Category.comida: [
        'restaurant', 'comida', 'food', 'pizza', 'cafe', 'coffee',
        'supermercado', 'grocery', 'market', 'almacen', 'panaderia',
        'delivery', 'uber eats', 'pedidos ya', 'dominos'
      ],
      Category.viajes: [
        'uber', 'taxi', 'metro', 'bus', 'transporte', 'combustible',
        'bencina', 'peaje', 'parking', 'estacionamiento', 'avion',
        'hotel', 'viaje', 'copec', 'shell', 'esso'
      ],
      Category.ocio: [
        'cine', 'theater', 'netflix', 'spotify', 'gaming', 'juegos',
        'entretenimiento', 'concert', 'evento', 'gym', 'gimnasio'
      ],
      Category.salud: [
        'farmacia', 'pharmacy', 'doctor', 'medico', 'hospital',
        'clinica', 'salud', 'dental', 'optica'
      ],
      Category.servicios: [
        'luz', 'agua', 'gas', 'telefono', 'internet', 'cable',
        'servicio', 'enel', 'aguas andinas', 'metrogas', 'movistar',
        'claro', 'entel', 'vtr'
      ],
    };
    
    // Buscar coincidencias en palabras clave
    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (descriptionLower.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    // Categorización por tipo de transacción
    switch (transactionType.toLowerCase()) {
      case 'transferencia':
        return Category.servicios;
      case 'suscripción':
        return Category.servicios;
      default:
        return Category.trabajo; // Categoría por defecto
    }
  }
}

/// Información de transacción bancaria extraída de un correo
class BankTransactionInfo {
  final double amount;
  final String transactionType;
  final String merchantOrDescription;
  final DateTime date;
  final bool isIncome;
  final String bank;
  final EmailInfo originalEmail;
  
  BankTransactionInfo({
    required this.amount,
    required this.transactionType,
    required this.merchantOrDescription,
    required this.date,
    required this.isIncome,
    required this.bank,
    required this.originalEmail,
  });
  
  /// Convierte la información de transacción a un objeto Expense
  Expense convertToExpense() {
    return Expense(
      title: '$bank: $transactionType',
      amount: amount,
      date: date,
      category: BankEmailParser._determineCategory(transactionType, merchantOrDescription),
    );
  }
}
