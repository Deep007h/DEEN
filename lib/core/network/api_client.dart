import 'dart:async';
import 'package:dio/dio.dart';

/// Pre-configured Dio HTTP client with retry interceptor, timeouts, and descriptive User-Agent.
class ApiClient {
  static const String defaultUserAgent =
      'DEEN/1.0 (Linux; https://github.com/animeapp/deen; contact: user@deen.app)';

  final Dio dio;

  ApiClient({
    String? baseUrl,
    String userAgent = defaultUserAgent,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
    int maxRetries = 2,
    Duration retryInterval = const Duration(milliseconds: 800),
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? '',
            connectTimeout: connectTimeout,
            receiveTimeout: receiveTimeout,
            headers: {
              'User-Agent': userAgent,
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(_RetryInterceptor(
      dio,
      maxRetries: maxRetries,
      retryInterval: retryInterval,
    ));
  }
}

/// Custom interceptor that retries idempotent requests on network errors or 5xx server errors.
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryInterval;

  _RetryInterceptor(
    this.dio, {
    this.maxRetries = 2,
    this.retryInterval = const Duration(milliseconds: 800),
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    // Do not retry cancelled requests or non-retryable errors (e.g. 400 Bad Request, 404 Not Found)
    if (err.type == DioExceptionType.cancel ||
        (err.response != null && err.response!.statusCode != null && err.response!.statusCode! < 500)) {
      return handler.next(err);
    }

    final retryCount = (requestOptions.extra['retryCount'] as int? ?? 0);
    if (retryCount < maxRetries) {
      requestOptions.extra['retryCount'] = retryCount + 1;
      final backoff = retryInterval * (retryCount + 1);
      await Future.delayed(backoff);

      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      } catch (e) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
