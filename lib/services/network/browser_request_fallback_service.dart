import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../constants.dart';
import 'adapters/platform_adapter.dart';
import 'cookie/cookie_sync_service.dart';
import 'interceptors/request_header_interceptor.dart';

class BrowserRequestFallbackService {
  BrowserRequestFallbackService._internal();

  static final BrowserRequestFallbackService instance =
      BrowserRequestFallbackService._internal();

  Dio? _dio;

  Future<Response<dynamic>> retry(RequestOptions original) async {
    final dio = await _getDio();
    final headers = Map<String, dynamic>.from(original.headers)
      ..remove('cookie')
      ..remove('Cookie');
    final extra = Map<String, dynamic>.from(original.extra)
      ..['_browserFallbackRetried'] = true
      ..['preferBrowserSession'] = true
      ..['skipScheduler'] = true;

    final request = original.copyWith(
      baseUrl: '',
      path: original.uri.toString(),
      headers: headers,
      extra: extra,
    );

    debugPrint(
      '[BrowserFallback] retry ${request.method} ${original.uri}',
    );
    return dio.fetch<dynamic>(request);
  }

  Future<Dio> _getDio() async {
    final existing = _dio;
    if (existing != null) return existing;

    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        followRedirects: false,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 400,
      ),
    );

    configureWebViewFallbackAdapter(dio);
    dio.interceptors.add(RequestHeaderInterceptor(CookieSyncService()));
    _dio = dio;
    return dio;
  }
}
