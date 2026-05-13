/// One article in the news feed. Maps onto the Crypto News API
/// response shape; missing fields are tolerated so future schema
/// tweaks don't crash the parser.
class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.sourceName,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
    this.summary,
    this.sentiment,
    this.tickers = const [],
  });

  final String title;
  final String sourceName;
  final String url;
  final String imageUrl;
  final DateTime publishedAt;
  final String? summary;

  /// `"Positive"` / `"Negative"` / `"Neutral"` (or null when the
  /// API omits sentiment scoring).
  final String? sentiment;

  /// Tickers mentioned in the article (e.g. `["BTC", "ETH"]`).
  final List<String> tickers;

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: (json['title'] ?? '').toString(),
      sourceName: (json['source_name'] ?? '').toString(),
      url: (json['news_url'] ?? json['url'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      publishedAt: _parseDate(json['date']),
      summary: (json['text'] as String?)?.trim().isEmpty == true
          ? null
          : (json['text'] as String?)?.trim(),
      sentiment: (json['sentiment'] as String?)?.trim().isEmpty == true
          ? null
          : (json['sentiment'] as String?)?.trim(),
      tickers: (json['tickers'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
    );
  }

  /// Cryptonews-api emits RFC-1123-style strings such as
  /// `"Mon, 13 May 2026 10:00:00 -0400"`. Dart's parser handles the
  /// canonical ISO form natively; the helper falls back gracefully
  /// for the RFC variant so the UI still has a sortable timestamp.
  static DateTime _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(raw);
    } catch (_) {
      try {
        // RFC 1123 → strip weekday and try again as
        // "13 May 2026 10:00:00 -0400" which Dart can parse.
        final parts = raw.split(', ');
        if (parts.length == 2) {
          return _httpDateToDateTime(parts[1]);
        }
      } catch (_) {}
      return DateTime.now();
    }
  }

  static DateTime _httpDateToDateTime(String s) {
    // "13 May 2026 10:00:00 -0400"
    final m = RegExp(
      r'(\d+) (\w+) (\d+) (\d+):(\d+):(\d+) ([+-]\d{4})',
    ).firstMatch(s);
    if (m == null) return DateTime.now();
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final iso =
        '${m.group(3)}-${months[m.group(2)!].toString().padLeft(2, '0')}-'
        '${m.group(1)!.padLeft(2, '0')}T${m.group(4)}:${m.group(5)}:${m.group(6)}${m.group(7)}';
    return DateTime.parse(iso).toLocal();
  }
}
