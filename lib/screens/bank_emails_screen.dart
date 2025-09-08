import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services_bd/gmail_provider.dart';
import '../services_bd/bank_email_parser.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../service_db_local/crud.dart';

class BankEmailsScreen extends ConsumerStatefulWidget {
  const BankEmailsScreen({super.key});

  @override
  ConsumerState<BankEmailsScreen> createState() => _BankEmailsScreenState();
}

class _BankEmailsScreenState extends ConsumerState<BankEmailsScreen> {
  String _selectedBank = '';

  // Lista de bancos principales en Chile
  final List<Map<String, dynamic>> _banks = [
    {'name': 'Banco Santander', 'value': 'santander', 'icon': Icons.account_balance},
    {'name': 'Banco de Chile', 'value': 'banco_chile', 'icon': Icons.account_balance},
    {'name': 'BCI', 'value': 'bci', 'icon': Icons.account_balance},
    {'name': 'Banco Estado', 'value': 'bancoestado', 'icon': Icons.account_balance},
    {'name': 'Scotiabank', 'value': 'scotiabank', 'icon': Icons.account_balance},
    {'name': 'Itaú', 'value': 'itau', 'icon': Icons.account_balance},
    {'name': 'Banco Falabella', 'value': 'falabella', 'icon': Icons.account_balance},
    {'name': 'Banco Ripley', 'value': 'ripley', 'icon': Icons.account_balance},
    {'name': 'Banco Security', 'value': 'security', 'icon': Icons.account_balance},
    {'name': 'Coopeuch', 'value': 'coopeuch', 'icon': Icons.account_balance},
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(gmailAuthStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Correos Bancarios'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(authState),
    );
  }

  Widget _buildBody(GmailAuthState authState) {
    switch (authState.status) {
      case GmailAuthStatus.authenticated:
        return _buildBankEmailsList();
      case GmailAuthStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case GmailAuthStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${authState.errorMessage}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(gmailAuthStateProvider.notifier).authenticate();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      default:
        return _buildAuthenticationPrompt();
    }
  }

  Widget _buildAuthenticationPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mail, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Acceso a Gmail requerido',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Para acceder a tus correos bancarios, necesitas autorizar el acceso a Gmail.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await ref.read(gmailServiceProvider).initializeWithCurrentUser();
                ref.read(gmailAuthStateProvider.notifier).authenticate();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al autenticar: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.login),
            label: const Text('Autorizar Gmail'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankEmailsList() {
    return Column(
      children: [
        // Selector de banco
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona un banco:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedBank.isEmpty ? null : _selectedBank,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Selecciona un banco',
                ),
                items: _banks.map((bank) {
                  return DropdownMenuItem<String>(
                    value: bank['value'],
                    child: Row(
                      children: [
                        Icon(bank['icon'], size: 20),
                        const SizedBox(width: 8),
                        Text(bank['name']),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBank = value ?? '';
                  });
                },
              ),
            ],
          ),
        ),
        // Lista de correos
        Expanded(
          child: _selectedBank.isEmpty
              ? const Center(
                  child: Text(
                    'Selecciona un banco para ver los correos',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : _buildEmailsForBank(_selectedBank),
        ),
      ],
    );
  }

  Widget _buildEmailsForBank(String bank) {
    final emailsAsync = ref.watch(specificBankEmailsProvider(bank));

    return emailsAsync.when(
      data: (emails) {
        // Filtrar solo correos que contengan información financiera válida
        final financialEmails = emails.where((email) {
          final transactionInfo = BankEmailParser.parseEmailContent(email);
          return transactionInfo != null; // Solo mostrar correos con información de transacciones
        }).toList();

        if (financialEmails.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No se encontraron correos con información financiera'),
                SizedBox(height: 8),
                Text(
                  'Los correos deben contener información de montos o transacciones',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: financialEmails.length,
          itemBuilder: (context, index) {
            final email = financialEmails[index];
            final transactionInfo = BankEmailParser.parseEmailContent(email)!; // Sabemos que no es null
            
            // Determinar colores según si es ingreso o gasto
            Color avatarColor;
            Color amountColor;
            Color amountBackgroundColor;
            IconData iconData;
            Color trailingIconColor;
            
            if (transactionInfo.isIncome) {
              // Ingreso - Verde
              avatarColor = Colors.green;
              amountColor = Colors.green;
              amountBackgroundColor = Colors.green.withValues(alpha: 0.1);
              iconData = Icons.arrow_downward; // Flecha hacia abajo = dinero que llega
              trailingIconColor = Colors.green;
            } else {
              // Gasto - Rojo
              avatarColor = Colors.red;
              amountColor = Colors.red;
              amountBackgroundColor = Colors.red.withValues(alpha: 0.1);
              iconData = Icons.arrow_upward; // Flecha hacia arriba = dinero que sale
              trailingIconColor = Colors.red;
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: avatarColor,
                  child: Icon(
                    iconData,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  email.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email.from,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: amountBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '\$${transactionInfo.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: amountColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: transactionInfo.isIncome 
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            transactionInfo.isIncome ? 'INGRESO' : 'GASTO',
                            style: TextStyle(
                              color: transactionInfo.isIncome ? Colors.green : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Icon(Icons.add_circle_outline, color: trailingIconColor),
                onTap: () => _showCreateExpenseDialog(transactionInfo),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error al cargar correos: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(specificBankEmailsProvider(bank)),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateExpenseDialog(BankTransactionInfo transactionInfo) {
    String title = '${transactionInfo.bank}: ${transactionInfo.transactionType}';
    Category selectedCategory = Category.trabajo;
    double amount = transactionInfo.amount;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Crear Gasto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo de título
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Título del gasto',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: title),
                      onChanged: (value) => title = value,
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de monto
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Monto (\$)',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: amount.toStringAsFixed(0)),
                      onChanged: (value) {
                        amount = double.tryParse(value) ?? amount;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Selector de categoría
                    DropdownButtonFormField<Category>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      items: Category.values.map((category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(_getCategoryIcon(category)),
                              const SizedBox(width: 8),
                              Text(_getCategoryName(category)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (Category? value) {
                        if (value != null) {
                          setState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Información adicional
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Banco: ${transactionInfo.bank}'),
                          Text('Fecha: ${transactionInfo.date.day}/${transactionInfo.date.month}/${transactionInfo.date.year}'),
                          Text('Descripción: ${transactionInfo.merchantOrDescription}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final expense = Expense(
                        title: title,
                        amount: amount,
                        date: transactionInfo.date,
                        category: selectedCategory,
                      );
                      
                      // Guardar en la base de datos local
                      await createExpenseLocal(expense);
                      
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gasto creado exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al crear gasto: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Crear Gasto'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(Category category) {
    switch (category) {
      case Category.comida:
        return Icons.restaurant;
      case Category.viajes:
        return Icons.flight;
      case Category.ocio:
        return Icons.movie;
      case Category.trabajo:
        return Icons.work;
      case Category.salud:
        return Icons.health_and_safety;
      case Category.servicios:
        return Icons.miscellaneous_services;
    }
  }

  String _getCategoryName(Category category) {
    switch (category) {
      case Category.comida:
        return 'Comida';
      case Category.viajes:
        return 'Viajes';
      case Category.ocio:
        return 'Ocio';
      case Category.trabajo:
        return 'Trabajo';
      case Category.salud:
        return 'Salud';
      case Category.servicios:
        return 'Servicios';
    }
  }
}
