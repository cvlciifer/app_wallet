import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_wallet/library_section/main_library.dart';
import '../../services/gmail_service.dart';

class GmailInboxPage extends StatefulWidget {
  const GmailInboxPage({Key? key}) : super(key: key);

  @override
  State<GmailInboxPage> createState() => _GmailInboxPageState();
}

class _GmailInboxPageState extends State<GmailInboxPage> {
  final GmailService _service = GmailService();
  late Future<List<GmailMessageInfo>> _futureMessages;

  @override
  void initState() {
    super.initState();
    _futureMessages = _loadMessages();
  }

  Future<List<GmailMessageInfo>> _loadMessages() async {
    // reset UI state if needed
    final signed = await _service.signInWithGmailScope();
    if (!signed) {
      throw Exception('Autenticación cancelada o permisos denegados');
    }

    try {
      // Filtrar por remitentes: Banco Estado y Banco Santander.
      // La consulta q puede usar dominios o nombres. Ajusta según los remitentes reales.
      final query = 'from:("BancoEstado" OR "Banco Santander" OR "@bancoestado.cl" OR "@santander.cl")';
      final msgs = await _service.listLatestMessages(maxResults: 20, query: query);
      return msgs;
    } catch (e) {
      rethrow;
    }
  }

  void _refresh() {
    setState(() {
      _futureMessages = _loadMessages();
    });
  }

  Widget _buildList(List<GmailMessageInfo> messages) {
    if (messages.isEmpty) {
      return const Center(child: Text('No hay correos en la bandeja de entrada'));
    }

    return ListView.separated(
      itemCount: messages.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final m = messages[index];
        String formattedDate = m.date;
        try {
          final parsed = DateTime.parse(m.date);
          formattedDate = DateFormat.yMMMd().add_Hm().format(parsed.toLocal());
        } catch (_) {
          // mantener la fecha original si no parsea
        }

        // Mostrar más información: subject, remitente, fecha y snippet.
        final subject = m.subject.isNotEmpty ? m.subject : '(sin asunto)';
        final snippet = m.snippet.replaceAll('\n', ' ').trim();

        // Detectar si el correo indica movimientos de dinero (entrada/salida)
        final textToAnalyze = '${subject.toLowerCase()} ${snippet.toLowerCase()} ${m.from.toLowerCase()}';
        const outKeywords = [
          'debito',
          'debited',
          'retir',
          'retirado',
          'cargo',
          'compra',
          'pag',
          'pagado',
          'pago',
          'salid',
          'retiro',
          'descuento',
          'cobro',
          'comprado'
        ];
        const inKeywords = [
          'acredit',
          'acreditado',
          'deposit',
          'deposito',
          'depositado',
          'abono',
          'ingres',
          'ingresado',
          'recib',
          'abon',
          'transferencia recibida'
        ];

        final bool indicatesOut = outKeywords.any((k) => textToAnalyze.contains(k));
        final bool indicatesIn = !indicatesOut && inKeywords.any((k) => textToAnalyze.contains(k));

        // Contenido principal de la tarjeta
        Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject
            Text(subject,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            // From + date row
            Row(
              children: [
                Expanded(
                    child: Text(m.from,
                        style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            // Snippet
            if (snippet.isNotEmpty)
              Text(snippet,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
          ],
        );

        // Overlay arrow según detección
        final List<Widget> overlays = [];
        if (indicatesOut) {
          overlays.add(Positioned(
            right: -8,
            top: -10,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Icon(Icons.arrow_upward, color: Colors.red, size: 18),
            ),
          ));
        } else if (indicatesIn) {
          overlays.add(Positioned(
            right: -8,
            top: -10,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Icon(Icons.arrow_downward, color: Colors.green, size: 18),
            ),
          ));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TicketCard(
            compactNotches: true,
            roundTopCorners: true,
            topCornerRadius: 7,
            overlays: overlays.isNotEmpty ? overlays : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: content,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gmail - Bandeja de entrada'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<GmailMessageInfo>>(
        future: _futureMessages,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final err = snapshot.error.toString();
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: $err', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _refresh, child: const Text('Reintentar')),
                  ],
                ),
              ),
            );
          }
          final msgs = snapshot.data ?? [];
          return _buildList(msgs);
        },
      ),
    );
  }
}
