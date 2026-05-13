import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/news/crypto_news_client.dart';
import '../data/news/news_models.dart';

final newsServiceProvider =
    Provider<CryptoNewsClient>((ref) => CryptoNewsClient());

/// Front-page news. Cached at the provider level — pull-to-refresh
/// invalidates this entry to force a re-fetch.
final latestNewsProvider = FutureProvider<List<NewsArticle>>((ref) async {
  return ref.watch(newsServiceProvider).latest();
});
