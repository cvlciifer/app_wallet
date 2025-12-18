class GmailMessageInfo {
  final String id;
  final String from;
  final String subject;
  final String date;
  final bool isRead;
  final String snippet;
  final List<String> labels;

  GmailMessageInfo({
    required this.id,
    required this.from,
    required this.subject,
    required this.date,
    this.isRead = true,
    this.snippet = '',
    this.labels = const [],
  });
}
