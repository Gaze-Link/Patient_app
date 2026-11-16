import 'package:dio/dio.dart';

/// Builds an API client after the environment supplies a real backend URL.
/// No server address or endpoint is assumed by the patient app.
Dio createApiClient({
  required Uri baseUri,
  Iterable<Interceptor> interceptors = const [],
}) {
  if ((baseUri.scheme != 'https' && baseUri.scheme != 'http') ||
      baseUri.host.isEmpty) {
    throw ArgumentError.value(
      baseUri,
      'baseUri',
      'Must be an HTTP(S) URI with a host.',
    );
  }

  return Dio(
    BaseOptions(
      baseUrl: baseUri.toString(),
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    ),
  )..interceptors.addAll(interceptors);
}
