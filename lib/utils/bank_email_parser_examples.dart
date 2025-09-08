import '../services_bd/bank_email_parser.dart';

/// Ejemplos y casos de prueba para el parser de correos bancarios
class BankEmailParserExamples {
  
  /// Ejemplos de correos bancarios reales (simulados)
  static final List<Map<String, String>> emailExamples = [
    {
      'subject': 'Notificación de transferencia - Banco Santander',
      'body': '''
      Estimado cliente,
      
      Se ha realizado una transferencia desde su cuenta:
      
      Monto: \$150.000
      Fecha: 08/09/2024
      Desde: Cuenta Corriente ****1234
      Hacia: Juan Pérez
      Concepto: Pago arriendo
      
      Su nuevo saldo es \$450.000
      ''',
      'from': 'notificaciones@santander.cl',
    },
    {
      'subject': 'Compra con tarjeta de débito - BCI',
      'body': '''
      Su tarjeta de débito terminada en 5678 fue utilizada para una compra:
      
      Comercio: SUPERMERCADO JUMBO
      Monto: \$75.500
      Fecha: 08/09/2024 14:30
      Autorización: 123456
      
      Consulte su saldo en bci.cl
      ''',
      'from': 'alertas@bci.cl',
    },
    {
      'subject': 'Depósito en su cuenta - Banco Estado',
      'body': '''
      Se registró un depósito en su CuentaRUT:
      
      Valor depositado: \$200.000
      Fecha y hora: 08/09/2024 10:15
      Sucursal: Plaza Italia
      
      Su saldo disponible es \$850.000
      ''',
      'from': 'cuentarut@bancoestado.cl',
    },
    {
      'subject': 'Cargo mensual tarjeta de crédito',
      'body': '''
      Banco Falabella informa:
      
      Se ha efectuado el cargo mensual de su tarjeta:
      Cargo por mantención: \$3.500
      Cargo por seguro: \$12.000
      Total cargos: \$15.500
      
      Fecha de vencimiento: 15/09/2024
      ''',
      'from': 'tarjetas@bancofalabella.cl',
    },
    {
      'subject': 'Retiro en cajero automático',
      'body': '''
      Se realizó un retiro desde su cuenta:
      
      Cajero: Mall Plaza Norte
      Monto retirado: \$50.000
      Fecha: 08/09/2024 18:45
      Comisión: \$1.200
      
      Saldo disponible: \$298.800
      ''',
      'from': 'seguridad@scotiabank.cl',
    },
  ];

  /// Patrones mejorados para diferentes formatos de montos chilenos
  static final List<String> amountPatterns = [
    // Formato con símbolo de peso
    r'\$\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)', // $123.456,78 o $123.456
    r'CLP\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)', // CLP 123.456,78
    r'clp\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)', // clp 123.456,78
    
    // Palabras clave con monto
    r'monto[:\s]*\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)',
    r'valor[:\s]*\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)',
    r'total[:\s]*\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)',
    r'cargo[:\s]*\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)',
    r'abono[:\s]*\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)',
    r'depósito[:\s]*\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)',
    r'deposito[:\s]*\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)',
    r'transferencia[:\s]*\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)',
    
    // Contextos específicos
    r'por\s*\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)',
    r'de\s*\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)',
    r'pago\s*de\s*\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)',
    r'compra\s*por\s*\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)',
    r'retiro\s*de\s*\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)',
    
    // Formatos menos comunes
    r'(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)\s*pesos',
    r'(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)\s*CLP',
    r'(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)\s*clp',
  ];

  /// Palabras clave para identificar tipos de transacciones
  static final Map<String, List<String>> transactionKeywords = {
    'Transferencia': [
      'transferencia', 'transfer', 'envío', 'envio', 'giro', 'remesa'
    ],
    'Pago': [
      'pago', 'cargo', 'compra', 'purchase', 'débito', 'debito'
    ],
    'Depósito': [
      'depósito', 'deposito', 'abono', 'ingreso', 'acreditación', 'acreditacion'
    ],
    'Retiro': [
      'retiro', 'extracción', 'extraccion', 'giro', 'cajero', 'atm'
    ],
    'Tarjeta': [
      'tarjeta', 'card', 'débito', 'crédito', 'credito', 'debito'
    ],
    'Comisión': [
      'comisión', 'comision', 'mantención', 'mantencion', 'fee', 'cargo mensual'
    ],
    'Seguro': [
      'seguro', 'insurance', 'protección', 'proteccion', 'cobertura'
    ],
  };

  /// Palabras clave para determinar si es ingreso o gasto
  static final List<String> incomeKeywords = [
    'depósito', 'deposito', 'abono', 'ingreso', 'acreditación', 'acreditacion',
    'recepción', 'recepcion', 'transferencia recibida', 'pago recibido',
    'devolución', 'devolucion', 'reembolso', 'reintegro'
  ];

  static final List<String> expenseKeywords = [
    'cargo', 'compra', 'pago', 'débito', 'debito', 'retiro', 'extracción',
    'extraccion', 'comisión', 'comision', 'transferencia enviada',
    'mantención', 'mantencion', 'cuota', 'interés', 'interes'
  ];

  /// Mapeo de comercios a categorías
  static final Map<String, String> merchantCategories = {
    // Supermercados y alimentación
    'jumbo': 'Supermercado',
    'lider': 'Supermercado',
    'unimarc': 'Supermercado',
    'santa isabel': 'Supermercado',
    'tottus': 'Supermercado',
    'acuenta': 'Supermercado',
    
    // Transporte
    'uber': 'Transporte',
    'cabify': 'Transporte',
    'didi': 'Transporte',
    'metro': 'Transporte',
    'transantiago': 'Transporte',
    'peaje': 'Transporte',
    'copec': 'Combustible',
    'shell': 'Combustible',
    'petrobras': 'Combustible',
    
    // Entretenimiento
    'cinemark': 'Entretenimiento',
    'cine hoyts': 'Entretenimiento',
    'netflix': 'Entretenimiento',
    'spotify': 'Entretenimiento',
    'amazon prime': 'Entretenimiento',
    
    // Salud
    'farmacia': 'Salud',
    'cruz verde': 'Salud',
    'salcobrand': 'Salud',
    'clinica': 'Salud',
    'hospital': 'Salud',
    'isapre': 'Salud',
    
    // Retail
    'falabella': 'Retail',
    'ripley': 'Retail',
    'paris': 'Retail',
    'la polar': 'Retail',
    'hites': 'Retail',
    
    // Servicios
    'movistar': 'Telecomunicaciones',
    'entel': 'Telecomunicaciones',
    'claro': 'Telecomunicaciones',
    'vtr': 'Telecomunicaciones',
    'chilquinta': 'Servicios Básicos',
    'enel': 'Servicios Básicos',
    'aguas andinas': 'Servicios Básicos',
    'metrogas': 'Servicios Básicos',
  };

  /// Función para probar el parser con los ejemplos
  static void testParser() {
    print('🔍 Probando parser de correos bancarios...\n');
    
    for (int i = 0; i < emailExamples.length; i++) {
      final example = emailExamples[i];
      print('📧 Ejemplo ${i + 1}: ${example['subject']}');
      
      // Simular EmailInfo
      final emailInfo = {
        'subject': example['subject']!,
        'body': example['body']!,
        'from': example['from']!,
        'snippet': example['body']!.substring(0, 100),
        'date': DateTime.now().toIso8601String(),
        'id': 'example_$i',
      };
      
      // Parsear información
      // final transaction = BankEmailParser.parseEmailContent(emailInfo);
      
      // if (transaction != null) {
      //   print('✅ Monto extraído: \$${transaction.amount}');
      //   print('📊 Tipo: ${transaction.transactionType}');
      //   print('📝 Descripción: ${transaction.description}');
      //   print('🏦 Banco: ${transaction.bank}');
      //   print('💰 Es ingreso: ${transaction.isIncome}');
      // } else {
      //   print('❌ No se pudo extraer información');
      // }
      
      print('');
    }
  }

  /// Función para generar regex pattern optimizado
  static String generateOptimizedAmountPattern() {
    return r'\$?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)\s*(?:clp|pesos)?';
  }

  /// Función para detectar montos con mayor precisión
  static List<double> extractAllAmountsFromText(String text) {
    final amounts = <double>[];
    final pattern = generateOptimizedAmountPattern();
    final regex = RegExp(pattern, caseSensitive: false);
    
    final matches = regex.allMatches(text);
    
    for (final match in matches) {
      final amountStr = match.group(1);
      if (amountStr != null) {
        try {
          // Normalizar formato chileno a formato estándar
          final normalized = amountStr.replaceAll('.', '').replaceAll(',', '.');
          final amount = double.parse(normalized);
          amounts.add(amount);
        } catch (e) {
          print('Error parsing amount: $amountStr');
        }
      }
    }
    
    return amounts;
  }
}
