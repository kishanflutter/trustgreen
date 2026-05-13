import 'package:dio/dio.dart';

import '../../core/env/app_env.dart';
import 'news_models.dart';

/// Thin Dio wrapper around cryptonews-api.com.
///
/// Returns `[]` on every failure path (rate-limit, network error,
/// schema drift). The UI shows an "Unavailable" state instead of
/// crashing.
class CryptoNewsClient {
  CryptoNewsClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Fetches the front-page list. The default section is whatever
  /// `NEWS_SECTION=` is set to in `.env` (typically `general`).
  Future<List<NewsArticle>> latest({
    String? section,
    int items = 25,
    int page = 1,
  }) async {
    final apiKey = AppEnv.newsApiKey;
    if (apiKey == null) return const <NewsArticle>[];

    final qp = <String, dynamic>{
      'section': section ?? AppEnv.newsSection,
      'items': '$items',
      'page': '$page',
      'token': apiKey,
    };

    final base = AppEnv.newsApiUrl;
    final hostUri = Uri.parse(base);

    final uri = Uri(
      scheme: hostUri.scheme.isEmpty ? 'https' : hostUri.scheme,
      host: hostUri.host.isEmpty ? base : hostUri.host,
      path: '/api/v1/category',
      queryParameters: qp,
    );

    try {
      final res = await _dio.getUri<Map<String, dynamic>>(
        uri,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final data = res.data ?? const {};
      final list = data['data'];
      if (list is! List) return const <NewsArticle>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map(NewsArticle.fromJson)
          .toList();
    } on DioException {
      return const <NewsArticle>[];
    }
  }
}
