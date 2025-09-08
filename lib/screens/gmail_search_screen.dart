import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services_bd/gmail_provider.dart';
import '../services_bd/gmail_service.dart';

class GmailSearchScreen extends ConsumerStatefulWidget {
  const GmailSearchScreen({super.key});

  @override
  ConsumerState<GmailSearchScreen> createState() => _GmailSearchScreenState();
}

class _GmailSearchScreenState extends ConsumerState<GmailSearchScreen> {
  final TextEditingController _subjectController = TextEditingController();
  String _currentSearchTerm = '';

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(gmailAuthStateProvider);
    final authNotifier = ref.read(gmailAuthStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Correos Gmail'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          if (authState.status == GmailAuthStatus.authenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authNotifier.signOut(),
              tooltip: 'Cerrar sesión',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAuthSection(authState, authNotifier),
            const SizedBox(height: 20),
            if (authState.status == GmailAuthStatus.authenticated) ...[
              _buildSearchSection(),
              const SizedBox(height: 20),
              Expanded(child: _buildEmailsList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthSection(GmailAuthState authState, GmailAuthNotifier authNotifier) {
    switch (authState.status) {
      case GmailAuthStatus.initial:
      case GmailAuthStatus.unauthenticated:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(
                  Icons.email,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Conectar con Gmail',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para buscar correos por asunto, necesitas autenticarte con tu cuenta de Gmail.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => authNotifier.authenticate(),
                  icon: const Icon(Icons.login),
                  label: const Text('Conectar con Gmail'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );

      case GmailAuthStatus.loading:
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Conectando con Gmail...'),
              ],
            ),
          ),
        );

      case GmailAuthStatus.authenticated:
        return Card(
          color: Colors.green[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Conectado con Gmail exitosamente',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );

      case GmailAuthStatus.error:
        return Card(
          color: Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: Colors.red[600],
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Error de conexión',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (authState.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    authState.errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => authNotifier.authenticate(),
                  child: const Text('Intentar de nuevo'),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildSearchSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Buscar por asunto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe el asunto del correo...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _searchEmails,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _searchEmails(_subjectController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailsList() {
    if (_currentSearchTerm.isEmpty) {
      return const Center(
        child: Text(
          'Ingresa un asunto para buscar correos',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    final emailsAsync = ref.watch(emailsBySubjectProvider(_currentSearchTerm));

    return emailsAsync.when(
      data: (emails) {
        if (emails.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron correos con el asunto\n"$_currentSearchTerm"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: emails.length,
          itemBuilder: (context, index) {
            final email = emails[index];
            return _buildEmailCard(email);
          },
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Buscando correos...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al buscar correos:\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(emailsBySubjectProvider(_currentSearchTerm)),
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailCard(EmailInfo email) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            email.from.isNotEmpty ? email.from[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          email.subject.isNotEmpty ? email.subject : 'Sin asunto',
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'De: ${email.from}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (email.date.isNotEmpty)
              Text(
                'Fecha: ${email.date}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (email.snippet.isNotEmpty) ...[
                  const Text(
                    'Resumen:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(email.snippet),
                  const SizedBox(height: 12),
                ],
                if (email.body.isNotEmpty) ...[
                  const Text(
                    'Contenido:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      email.body,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _searchEmails(String subject) {
    if (subject.trim().isNotEmpty) {
      setState(() {
        _currentSearchTerm = subject.trim();
      });
    }
  }
}
