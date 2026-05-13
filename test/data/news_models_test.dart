import 'package:flutter_test/flutter_test.dart';
import 'package:trustgreen/data/news/news_models.dart';

void main() {
  group('NewsArticle.fromJson', () {
    test('parses a minimal payload', () {
      final article = NewsArticle.fromJson(const {
        'title': 'Hello',
        'source_name': 'Tester',
        'news_url': 'https://example.com/a',
        'image_url': 'https://example.com/i.png',
        'date': '2026-05-13T10:00:00Z',
      });
      expect(article.title, 'Hello');
      expect(article.sourceName, 'Tester');
      expect(article.url, 'https://example.com/a');
      expect(article.imageUrl, 'https://example.com/i.png');
      expect(article.publishedAt.year, 2026);
      expect(article.summary, isNull);
      expect(article.tickers, isEmpty);
    });

    test('parses RFC-1123 date strings emitted by cryptonews-api', () {
      final article = NewsArticle.fromJson(const {
        'title': 'x',
        'source_name': 'y',
        'news_url': 'https://e.com',
        'image_url': '',
        'date': 'Mon, 13 May 2026 10:00:00 -0400',
      });
      // The exact local-time offset depends on the host, but the
      // UTC component must match the input.
      final utc = article.publishedAt.toUtc();
      expect(utc.year, 2026);
      expect(utc.month, 5);
      expect(utc.day, 13);
      expect(utc.hour, 14); // 10:00 -0400 → 14:00 UTC
    });

    test('keeps tickers and sentiment when present', () {
      final article = NewsArticle.fromJson(const {
        'title': 't',
        'source_name': 's',
        'news_url': 'u',
        'image_url': '',
        'date': '2026-05-13T10:00:00Z',
        'sentiment': 'Positive',
        'tickers': ['BTC', 'ETH'],
        'text': '   Body text   ',
      });
      expect(article.sentiment, 'Positive');
      expect(article.tickers, equals(['BTC', 'ETH']));
      expect(article.summary, 'Body text');
    });

    test('handles missing date gracefully', () {
      final article = NewsArticle.fromJson(const {
        'title': 't',
        'source_name': 's',
        'news_url': 'u',
        'image_url': '',
      });
      // No throws; publishedAt populated with "now"-ish value.
      expect(article.publishedAt, isA<DateTime>());
    });
  });
}
