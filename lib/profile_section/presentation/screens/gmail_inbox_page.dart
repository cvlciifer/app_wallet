import 'package:app_wallet/library_section/main_library.dart';

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
    final signed = await _service.signInWithGmailScope();
    if (!signed) {
      throw Exception('Autenticación cancelada o permisos denegados');
    }

    try {
      const query =
          'from:("BancoEstado" OR "@bancoestado.cl" OR "noreply@correo.bancoestado.cl" OR "notificaciones@correo.bancoestado.cl")';
      final msgs = await _service.listLatestMessages(maxResults: 50, query: query);
      final outgoing = msgs.where((m) => _isOutgoingMessage(m)).toList();
      return outgoing;
    } catch (e) {
      rethrow;
    }
  }

  bool _isOutgoingMessage(GmailMessageInfo m) {
    final textToAnalyze = '${m.subject} ${m.snippet} ${m.from}'.toLowerCase();

    final knownSenders = <String>[
      'noreply@correo.bancoestado.cl',
      'notificaciones@correo.bancoestado.cl',
    ];

    final bancoEstadoPhrases = <String>[
      'se ha realizado una transferencia desde su cuenta corriente',
      'se ha realizado una compra',
      'se ha efectuado un pago a través de su tarjeta de débito',
      'se ha descontado el monto de',
      'ha realizado una compra en',
      'le informamos que su pago ha sido procesado exitosamente',
      'se ha cargado el monto correspondiente a su tarjeta',
    ];

    final normalized = textToAnalyze.replaceAll('é', 'e').replaceAll('ó', 'o').replaceAll('á', 'a');
    final normalizedFrom = m.from.toLowerCase().replaceAll('é', 'e').replaceAll('ó', 'o').replaceAll('á', 'a');

    if (knownSenders.any((s) => normalizedFrom.contains(s))) {
      if (normalized.contains('pago') ||
          normalized.contains('cargo') ||
          normalized.contains('transferencia') ||
          RegExp(r'\$\s*\d').hasMatch(normalized)) {
        return true;
      }
    }

    for (final p in bancoEstadoPhrases) {
      final pn = p.replaceAll('ó', 'o').replaceAll('é', 'e').replaceAll('á', 'a');
      if (normalized.contains(pn)) return true;
    }

    final generalPatterns = <RegExp>[
      RegExp(r'se ha descontado el monto de\s*\$?\s*\d', caseSensitive: false),
      RegExp(r'se debi?t?o?\b.*\$?\s*\d', caseSensitive: false),
      RegExp(r'pago efectuado.*tarjeta', caseSensitive: false),
      RegExp(r'transferencia enviad', caseSensitive: false),
      RegExp(r'ha realizado una compra en|compra por internet|compra registrada', caseSensitive: false),
      RegExp(r'cargo automatico|cargo por pago|se realizo un cargo', caseSensitive: false),
    ];

    for (final re in generalPatterns) {
      if (re.hasMatch(normalized)) return true;
    }

    return false;
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
        } catch (_) {}

        final subject = m.subject.isNotEmpty ? m.subject : '(sin asunto)';
        final snippet = m.snippet.replaceAll('\n', ' ').trim();

        final textToAnalyze = '${subject.toLowerCase()} ${snippet.toLowerCase()} ${m.from.toLowerCase()}';
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

        final bool indicatesOut = _isOutgoingMessage(m);
        final bool indicatesIn = !indicatesOut && inKeywords.any((k) => textToAnalyze.contains(k));

        Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
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
            if (snippet.isNotEmpty)
              Text(snippet,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
          ],
        );

        final List<Widget> overlays = [];
        if (indicatesOut) {
          overlays.add(const Positioned(
            right: -8,
            top: -10,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Icon(Icons.arrow_upward, color: Colors.red, size: 18),
            ),
          ));
        } else if (indicatesIn) {
          overlays.add(const Positioned(
            right: -8,
            top: -10,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Icon(Icons.arrow_downward, color: Colors.green, size: 18),
            ),
          ));
        }

        return GestureDetector(
          onTap: () => _onMessageTap(m),
          child: Padding(
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
          ),
        );
      },
    );
  }

  void _onMessageTap(GmailMessageInfo m) async {
    String body = await _service.getMessageBody(m.id);

    final amountMatch = RegExp(r'\$\s*([\d.,]+)').firstMatch(body);
    double? amount;
    if (amountMatch != null) {
      final raw = amountMatch.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      amount = double.tryParse(raw);
    }

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(m.date);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final title = m.subject.isNotEmpty ? m.subject : 'Gasto detectado';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.7;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: TicketCard(
            roundTopCorners: true,
            topCornerRadius: 10,
            compactNotches: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    AwText.bold(
                      title,
                      size: 16,
                    ),
                    const SizedBox(height: 8),
                    AwText(
                      text: 'Fecha: ${DateFormat.yMMMd().add_Hm().format(parsedDate.toLocal())}',
                    ),
                    const SizedBox(height: 8),
                    if (amount != null)
                      AwText(
                        text: 'Monto: ${NumberFormat.simpleCurrency(locale: 'en_US').format(amount)}',
                      ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: SelectableText(
                          body,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        WalletButton.textButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          buttonText: 'Cerrar',
                        ),
                        const SizedBox(width: 12),
                        WalletButton.primaryButton(
                          onPressed: () async {
                            Navigator.of(ctx).pop();

                            final expense = Expense(
                              title: title,
                              amount: amount ?? 0.0,
                              date: parsedDate,
                              category: Category.serviciosCuentas,
                            );
                            await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => NewExpenseScreen(initialExpense: expense),
                            ));
                          },
                          buttonText: 'Agregar gasto',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
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
