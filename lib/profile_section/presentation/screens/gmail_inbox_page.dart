import 'dart:developer';

import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

class GmailInboxPage extends StatefulWidget {
  const GmailInboxPage({Key? key}) : super(key: key);

  @override
  State<GmailInboxPage> createState() => _GmailInboxPageState();
}

class _GmailInboxPageState extends State<GmailInboxPage> {
  final GmailService _service = GmailService();
  late Future<List<GmailMessageInfo>> _futureMessages;
  final Map<String, double?> _amountCache = {};
  final Map<String, String?> _commentCache = {};
  final Set<String> _selectedIds = {};
  List<GmailMessageInfo> _currentMessages = [];
  double _pullDistance = 0.0;
  final double _refreshTriggerDistance = 100.0;
  bool _isRefreshing = false;

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
      final msgs =
          await _service.listLatestMessages(maxResults: 50, query: query);
      final outgoing = msgs.where((m) => _isOutgoingMessage(m)).toList();

      // Mensajes que deben ser revisados (cuerpo) para detectar frases de ingreso
      final toCheck = <GmailMessageInfo>[];
      final Set<String> excludeIds = {}; // ids a excluir de la lista (ingresos)

      String _normalizeText(String s) => s
          .toLowerCase()
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u');
      final incomePhrase = _normalizeText('Has recibido una transferencia');
      for (final m in outgoing) {
        final detected = _extractAmountFromMessage(m);
        if (detected != null) {
          _amountCache[m.id] = detected;
        } else {
          toCheck.add(m);
        }
      }

      await Future.wait(toCheck.map((m) async {
        try {
          final body = await _service.getMessageBody(m.id);
          final normalizedBody = _normalizeText(body);
          if (normalizedBody.contains(incomePhrase)) {
            // marca para excluir: es un ingreso recibido
            excludeIds.add(m.id);
          }
          final match = RegExp(r'\$\s*([\d.,]+)').firstMatch(body);
          if (match != null) {
            final raw =
                match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
            _amountCache[m.id] = double.tryParse(raw);
          } else {
            _amountCache[m.id] = null;
          }

          final commentMatch = RegExp(r'Comentario:[ \t]*(.*)',
                  caseSensitive: false, multiLine: true)
              .firstMatch(body);
          _commentCache[m.id] = commentMatch?.group(1)?.trim();
        } catch (_) {
          _amountCache[m.id] = null;
          _commentCache[m.id] = null;
        }
      }));

      // Además revisamos los mensajes que no requerían extracción previa (contienen el monto en subject/snippet)
      // y que aún no hayan sido verificados para la frase de ingreso.
      for (final m in outgoing) {
        if (excludeIds.contains(m.id)) continue;

        final combined = '${m.subject} ${m.snippet} ${m.from}';
        final normalizedCombined = _normalizeText(combined);
        if (normalizedCombined.contains(incomePhrase)) {
          excludeIds.add(m.id);
          continue;
        }

        // Si no fue verificado en la pasada anterior (no está en _amountCache), pedimos el cuerpo solo para detectar la frase
        if (!_amountCache.containsKey(m.id) && !_commentCache.containsKey(m.id)) {
          try {
            final body = await _service.getMessageBody(m.id);
            final normalizedBody = _normalizeText(body);
            if (normalizedBody.contains(incomePhrase)) {
              excludeIds.add(m.id);
            }
          } catch (_) {
            // ignore errors fetching body for phrase check
          }
        }
      }

      // Filtramos los mensajes de salida para quitar los que representan ingresos recibidos
      final filtered = outgoing.where((m) => !excludeIds.contains(m.id)).toList();

      return filtered;
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

    final normalized = textToAnalyze
        .replaceAll('é', 'e')
        .replaceAll('ó', 'o')
        .replaceAll('á', 'a');
    final normalizedFrom = m.from
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('ó', 'o')
        .replaceAll('á', 'a');

    if (knownSenders.any((s) => normalizedFrom.contains(s))) {
      if (normalized.contains('pago') ||
          normalized.contains('cargo') ||
          normalized.contains('transferencia') ||
          RegExp(r'\$\s*\d').hasMatch(normalized)) {
        return true;
      }
    }

    for (final p in bancoEstadoPhrases) {
      final pn =
          p.replaceAll('ó', 'o').replaceAll('é', 'e').replaceAll('á', 'a');
      if (normalized.contains(pn)) return true;
    }

    final generalPatterns = <RegExp>[
      RegExp(r'se ha descontado el monto de\s*\$?\s*\d', caseSensitive: false),
      RegExp(r'se debi?t?o?\b.*\$?\s*\d', caseSensitive: false),
      RegExp(r'pago efectuado.*tarjeta', caseSensitive: false),
      RegExp(r'transferencia enviad', caseSensitive: false),
      RegExp(
          r'ha realizado una compra en|compra por internet|compra registrada',
          caseSensitive: false),
      RegExp(r'cargo automatico|cargo por pago|se realizo un cargo',
          caseSensitive: false),
    ];

    for (final re in generalPatterns) {
      if (re.hasMatch(normalized)) return true;
    }

    return false;
  }

  String _displayName(String from) {
    if (from.isEmpty) return from;
    final trimmed = from.trim();
    final match = RegExp(r'^(.*?)(?:\s*<.*>)$').firstMatch(trimmed);
    if (match != null) {
      var name = match.group(1)!.trim();
      if (name.startsWith('"') && name.endsWith('"') && name.length > 1) {
        name = name.substring(1, name.length - 1).trim();
      }
      return name;
    }
    return trimmed;
  }

  double? _extractAmountFromMessage(GmailMessageInfo m) {
    final combined = '${m.subject} ${m.snippet} ${m.from}';
    final match = RegExp(r'\$\s*([\d.,]+)').firstMatch(combined);
    if (match != null) {
      final raw = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(raw);
    }
    return null;
  }

  void _refresh() {
    setState(() {
      _futureMessages = _loadMessages();
    });
  }

  Widget _buildList(List<GmailMessageInfo> messages) {
    _currentMessages = messages;
    if (messages.isEmpty) {
      return const Center(
          child: Text('No hay correos en la bandeja de entrada'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is OverscrollNotification &&
            notification.metrics.pixels <= 0 &&
            !_isRefreshing) {
          setState(() {
            _pullDistance += notification.overscroll.abs();
            if (_pullDistance > _refreshTriggerDistance * 2)
              _pullDistance = _refreshTriggerDistance * 2;
          });
        }

        if (notification is ScrollEndNotification) {
          final progress =
              (_pullDistance / _refreshTriggerDistance).clamp(0.0, 1.0);
          if (progress >= 1.0 && !_isRefreshing) {
            _performRefresh();
          } else if (!_isRefreshing) {
            setState(() {
              _pullDistance = 0.0;
            });
          }
        }

        return false;
      },
      child: Stack(
        children: [
          ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final m = messages[index];
              String formattedDate = m.date;
              try {
                final parsed = DateTime.parse(m.date);
                formattedDate =
                    DateFormat('dd/MM/yyyy').format(parsed.toLocal());
              } catch (_) {}

              final subject = m.subject.isNotEmpty ? m.subject : '(sin asunto)';
              final amountDetected =
                  _extractAmountFromMessage(m) ?? _amountCache[m.id];
              final comentarioRaw = _commentCache[m.id];
              String? comentarioToShow;
              if (comentarioRaw != null) {
                final firstLine =
                    comentarioRaw.split(RegExp(r'\r?\n')).first.trim();
                comentarioToShow =
                    firstLine.isEmpty ? 'sin comentario' : firstLine;
              }

              final bool indicatesOut = _isOutgoingMessage(m);
              final isSelected = _selectedIds.contains(m.id);

              Widget content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AwText.bold(
                    subject,
                    maxLines: 2,
                    size: 16,
                    textOverflow: TextOverflow.ellipsis,
                    color: AwColors.boldBlack,
                  ),
                  const SizedBox(height: 6),
                  AwText(
                    text: _displayName(m.from),
                    size: 13,
                    color: Colors.grey[800],
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 8),
                  AwText(
                    text: formattedDate,
                    size: 12,
                    color: Colors.grey,
                  ),
                  if (amountDetected != null)
                    AwText(
                      text: 'Monto: ${formatNumber(amountDetected)}',
                      size: 13,
                      color: indicatesOut ? Colors.red : Colors.green,
                    ),
                  const SizedBox(height: 8),
                  if (comentarioRaw != null) ...[
                    const SizedBox(height: 8),
                    AwText(
                      text: 'Comentario: $comentarioToShow',
                      size: 14,
                      color: Colors.black87,
                    ),
                  ],
                ],
              );

              final List<Widget> overlays = [];
              overlays.add(Positioned(
                right: -8,
                top: -10,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(unselectedWidgetColor: Colors.grey),
                      child: Checkbox(
                        value: isSelected,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedIds.add(m.id);
                            } else {
                              _selectedIds.remove(m.id);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ));

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () {
                  setState(() {
                    if (isSelected) {
                      _selectedIds.remove(m.id);
                    } else {
                      _selectedIds.add(m.id);
                    }
                  });
                },
                onTap: () {
                  if (_selectedIds.isNotEmpty) {
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(m.id);
                      } else {
                        _selectedIds.add(m.id);
                      }
                    });
                    return;
                  }
                  _onMessageTap(m);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: TicketCard(
                          compactNotches: true,
                          roundTopCorners: true,
                          topCornerRadius: 7,
                          overlays: overlays.isNotEmpty ? overlays : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: content,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final msgs = await _loadMessages();
      setState(() {
        _futureMessages = Future.value(msgs);
      });
    } catch (e) {
    } finally {
      setState(() {
        _isRefreshing = false;
        _pullDistance = 0.0;
      });
    }
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _openBatchConfirm() async {
    if (_selectedIds.isEmpty) return;

    final parsed = <Map<String, dynamic>>[];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const WalletLoader(),
    );

    for (final id in _selectedIds) {
      try {
        final m = _currentMessages.firstWhere((e) => e.id == id);
        final body = await _service.getMessageBody(m.id);

        String? comentario;
        double? amount;
        final commentMatch = RegExp(r'Comentario:[\t]*(.*)',
                caseSensitive: false, multiLine: true)
            .firstMatch(body);
        final rawComment = commentMatch?.group(1) ?? '';
        final firstLine = rawComment.split(RegExp(r'\r?\n')).first.trim();
        comentario = firstLine.isEmpty ? null : firstLine;

        final amountMatch = RegExp(r'\$\s*([\d.,]+)').firstMatch(body);
        if (amountMatch != null) {
          final raw =
              amountMatch.group(1)!.replaceAll('.', '').replaceAll(',', '.');
          amount = double.tryParse(raw);
        }

        DateTime parsedDate;
        try {
          parsedDate = DateTime.parse(m.date).toLocal();
        } catch (_) {
          parsedDate = DateTime.now();
        }

        final title = m.subject.isNotEmpty ? m.subject : 'Gasto detectado';

        parsed.add({
          'message': m,
          'amount': amount ?? _amountCache[m.id] ?? 0.0,
          'comment': comentario ?? title,
          'date': parsedDate,
          'title': comentario ?? title,
        });
      } catch (e) {}
    }

    Navigator.of(context, rootNavigator: true).pop();

    if (parsed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudieron parsear los correos seleccionados')));
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: TicketCard(
            roundTopCorners: true,
            topCornerRadius: 10,
            compactNotches: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.8,
                  maxWidth: MediaQuery.of(ctx).size.width * 0.95),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    AwText.bold('Vas a agregar ${parsed.length} gastos',
                        size: 16),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: parsed.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (c, i) {
                          final p = parsed[i];
                          final GmailMessageInfo m = p['message'];
                          final double amount = p['amount'] ?? 0.0;
                          final String title = p['title'] ?? '';
                          final DateTime date = p['date'];

                          return TicketCard(
                            compactNotches: true,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                          child:
                                              AwText.bold(title, maxLines: 2)),
                                      IconButton(
                                        onPressed: () {
                                          parsed.removeAt(i);
                                          setState(() {
                                            _selectedIds.remove(m.id);
                                          });
                                          Navigator.of(ctx).pop();
                                          Future.delayed(Duration.zero,
                                              () => _openBatchConfirm());
                                        },
                                        icon: const Icon(Icons.delete_forever,
                                            color: Colors.red),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  AwText(
                                      text:
                                          'Fecha: ${DateFormat('dd/MM/yyyy').format(date)}'),
                                  AwText(
                                      text: 'Monto: ${formatNumber(amount)}'),
                                  AwText(text: 'Categoría: cuenta y servicios'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        WalletButton.textButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            buttonText: 'Cancelar'),
                        const SizedBox(width: 12),
                        WalletButton.primaryButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await _addParsedExpenses(parsed);
                            },
                            buttonText: 'Agregar ${parsed.length} gastos'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addParsedExpenses(List<Map<String, dynamic>> parsed) async {
    if (parsed.isEmpty) return;

    parsed.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    final conn = await Connectivity().checkConnectivity();
    final hasConnection = conn != ConnectivityResult.none;
    final controller = context.read<WalletExpensesController>();

    try {
      try {
        riverpod.ProviderScope.containerOf(context, listen: false)
            .read(globalLoaderProvider.notifier)
            .state = true;
      } catch (_) {}

      for (final p in parsed) {
        final expense = Expense(
          title: p['title'] ?? 'Gasto detectado',
          amount: (p['amount'] as double?) ?? 0.0,
          date: p['date'] as DateTime,
          category: Category.serviciosCuentas,
        );

        try {
          await controller.addExpense(expense, hasConnection: hasConnection);
        } catch (e) {}
      }
    } finally {
      try {
        riverpod.ProviderScope.containerOf(context, listen: false)
            .read(globalLoaderProvider.notifier)
            .state = false;
      } catch (_) {}
    }

    _clearSelection();
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WalletHomePage()),
        (route) => false);
  }

  void _onMessageTap(GmailMessageInfo m) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const WalletLoader(
        color: AwColors.white,
      ),
    );

    String body;
    String? comentario;
    double? amount;
    try {
      body = await _service.getMessageBody(m.id);
      log('body: $body');

      final commentMatch =
          RegExp(r'Comentario:[\t]*(.*)', caseSensitive: false, multiLine: true)
              .firstMatch(body);
      final rawComment = commentMatch?.group(1) ?? '';
      final firstLine = rawComment.split(RegExp(r'\r?\n')).first.trim();
      comentario = firstLine.isEmpty ? null : firstLine;
      log('comentario: ${comentario ?? '<no comment>'}');
      final amountMatch = RegExp(r'\$\s*([\d.,]+)').firstMatch(body);
      if (amountMatch != null) {
        final raw =
            amountMatch.group(1)!.replaceAll('.', '').replaceAll(',', '.');
        amount = double.tryParse(raw);
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error cargando el correo')));
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(m.date).toLocal();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final title = m.subject.isNotEmpty ? m.subject : 'Gasto detectado';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.7;
        final maxWidth = MediaQuery.of(ctx).size.width * 1;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: TicketCard(
            roundTopCorners: true,
            topCornerRadius: 10,
            compactNotches: true,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: maxHeight, maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(5),
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
                    const SizedBox(height: 8),
                    if (amount != null)
                      AwText(
                        text: 'Monto: ${formatNumber(amount)}',
                      ),
                    if (comentario != null && comentario.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      AwText(
                        text: 'Comentario: $comentario',
                        size: 14,
                        color: Colors.black87,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: SelectableText(
                          body,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87),
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
                              title: comentario ?? title,
                              amount: amount ?? 0.0,
                              date: parsedDate,
                              category: Category.serviciosCuentas,
                            );

                            final returned =
                                await Navigator.of(context).push<Expense?>(
                              MaterialPageRoute(
                                  builder: (_) => NewExpenseScreen(
                                      initialExpense: expense)),
                            );

                            if (returned != null) {
                              final conn =
                                  await Connectivity().checkConnectivity();
                              final hasConnection =
                                  conn != ConnectivityResult.none;
                              final controller =
                                  context.read<WalletExpensesController>();

                              try {
                                try {
                                  riverpod.ProviderScope.containerOf(context,
                                          listen: false)
                                      .read(globalLoaderProvider.notifier)
                                      .state = true;
                                } catch (_) {}

                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const WalletHomePage()),
                                  (route) => false,
                                );

                                await controller.addExpense(returned,
                                    hasConnection: hasConnection);
                              } finally {
                                try {
                                  riverpod.ProviderScope.containerOf(context,
                                          listen: false)
                                      .read(globalLoaderProvider.notifier)
                                      .state = false;
                                } catch (_) {}
                              }
                            }
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
        title: _selectedIds.isNotEmpty
            ? Text('Seleccionados: ${_selectedIds.length}')
            : const Text('Gmail - Bandeja de entrada'),
        actions: [
          if (_selectedIds.isNotEmpty) ...[
            IconButton(
                onPressed: _clearSelection, icon: const Icon(Icons.clear)),
          ],
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<GmailMessageInfo>>(
        future: _futureMessages,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: WalletLoader());
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
                    ElevatedButton(
                        onPressed: _refresh, child: const Text('Reintentar')),
                  ],
                ),
              ),
            );
          }
          final msgs = snapshot.data ?? [];
          return _buildList(msgs);
        },
      ),
      floatingActionButton: _selectedIds.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: FloatingActionButton(
                backgroundColor: AwColors.appBarColor,
                onPressed: _openBatchConfirm,
                tooltip: 'Agregar gasto',
                child: const Icon(Icons.add, color: AwColors.white),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
