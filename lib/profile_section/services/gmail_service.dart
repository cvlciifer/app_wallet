import 'package:app_wallet/library_section/main_library.dart';
import 'package:googleapis/gmail/v1.dart' as gmail_api;
import 'package:http/http.dart' as http;
import 'dart:convert';

class GmailService {
  static final GmailService _instance = GmailService._internal();
  factory GmailService() => _instance;
  GmailService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/gmail.readonly',
    ],
  );

  GoogleSignInAccount? _currentUser;

  Future<bool> signInWithGmailScope() async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;

      if (account == null) {
        try {
          account = await _googleSignIn.signInSilently();
        } catch (_) {}
      }
      if (account == null) {
        account = await _googleSignIn.signIn();
        if (account == null) return false;
      }

      _currentUser = account;

      Map<String, String> headers = await account.authHeaders;
      if (!headers.containsKey('Authorization')) {
        try {
          await _googleSignIn.requestScopes(['https://www.googleapis.com/auth/gmail.readonly']);
        } catch (e) {
          debugPrint('requestScopes failed or not needed: $e');
        }

        final refreshed = _googleSignIn.currentUser;
        final accountToUse = refreshed ?? account;
        headers = await accountToUse.authHeaders;
      }

      if (!headers.containsKey('Authorization')) return false;

      return true;
    } catch (e) {
      debugPrint('Gmail signIn error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<http.Client> _authenticatedHttpClient() async {
    final account = _currentUser ?? _googleSignIn.currentUser;
    if (account == null) throw StateError('No signed in user');
    final headers = await account.authHeaders;
    return _GoogleAuthClient(headers);
  }

  Future<List<GmailMessageInfo>> listLatestMessages({int maxResults = 100, String? query}) async {
    final client = await _authenticatedHttpClient();
    try {
      final gmail = gmail_api.GmailApi(client);
      final messagesResponse =
          await gmail.users.messages.list('me', maxResults: maxResults, labelIds: ['INBOX'], q: query);
      final messages = messagesResponse.messages ?? [];
      final List<GmailMessageInfo> results = [];

      const int concurrency = 6; // number of parallel requests
      for (var i = 0; i < messages.length; i += concurrency) {
        final chunk = messages.skip(i).take(concurrency).toList();
        final futures = chunk.map((m) async {
          try {
            final msg = await gmail.users.messages.get(
              'me',
              m.id!,
              format: 'metadata',
              metadataHeaders: ['From', 'Subject', 'Date'],
            );

            final headers = msg.payload?.headers ?? [];
            String from = '';
            String subject = '';
            String date = '';
            for (final h in headers) {
              if (h.name?.toLowerCase() == 'from') from = h.value ?? '';
              if (h.name?.toLowerCase() == 'subject') subject = h.value ?? '';
              if (h.name?.toLowerCase() == 'date') date = h.value ?? '';
            }

            final labels = msg.labelIds ?? [];
            final isRead = !(labels.contains('UNREAD'));
            final snippet = msg.snippet ?? '';

            return GmailMessageInfo(
              id: m.id ?? '',
              from: from,
              subject: subject,
              date: date,
              isRead: isRead,
              snippet: snippet,
              labels: labels,
            );
          } catch (e) {
            debugPrint('Error fetching message ${m.id}: $e');
            return null;
          }
        }).toList();

        final chunkResults = await Future.wait(futures);
        for (final r in chunkResults) {
          if (r != null) results.add(r);
        }
      }

      return results;
    } finally {
      client.close();
    }
  }

  Future<String> getMessageBody(String id) async {
    final client = await _authenticatedHttpClient();
    try {
      final gmail = gmail_api.GmailApi(client);
      final msg = await gmail.users.messages.get('me', id, format: 'full');

      String extractAndDecode(String? data) {
        if (data == null || data.isEmpty) return '';
        final normalized = base64Url.normalize(data);
        try {
          return utf8.decode(base64Url.decode(normalized));
        } catch (_) {
          try {
            return utf8.decode(base64.decode(normalized));
          } catch (e) {
            return '';
          }
        }
      }

      String bodyText = '';

      final payload = msg.payload;
      if (payload == null) return msg.snippet ?? '';

      if (payload.body != null && (payload.body!.data ?? '').isNotEmpty) {
        bodyText = extractAndDecode(payload.body!.data);
      } else if (payload.parts != null && payload.parts!.isNotEmpty) {
        String? html;
        for (final p in payload.parts!) {
          final mime = p.mimeType ?? '';
          final data = p.body?.data ?? '';
          if (mime.toLowerCase().contains('text/plain') && data.isNotEmpty) {
            bodyText = extractAndDecode(data);
            break;
          }
          if (mime.toLowerCase().contains('text/html') && data.isNotEmpty) {
            html = extractAndDecode(data);
          }
          if ((p.parts ?? []).isNotEmpty) {
            for (final np in p.parts!) {
              final nm = np.mimeType ?? '';
              final nd = np.body?.data ?? '';
              if (nm.toLowerCase().contains('text/plain') && nd.isNotEmpty) {
                bodyText = extractAndDecode(nd);
                break;
              }
              if (nm.toLowerCase().contains('text/html') && nd.isNotEmpty) {
                html ??= extractAndDecode(nd);
              }
            }
            if (bodyText.isNotEmpty) break;
          }
        }
        if (bodyText.isEmpty && html != null) {
          bodyText = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
        }
      }

      if (bodyText.isEmpty) return msg.snippet ?? '';
      return bodyText.trim();
    } finally {
      client.close();
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
