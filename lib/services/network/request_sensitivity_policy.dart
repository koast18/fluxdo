import 'package:dio/dio.dart';

import '../../constants.dart';

class RequestSensitivityPolicy {
  static final List<Pattern> _sensitivePaths = <Pattern>[
    RegExp(r'^/topics/timings$'),
    RegExp(r'^/posts(?:\.json)?$'),
    RegExp(r'^/post_actions'),
    RegExp(r'^/notifications'),
    RegExp(r'^/presence'),
    RegExp(r'^/uploads'),
    RegExp(r'^/u/[^/]+/preferences'),
  ];

  static bool shouldAttemptBrowserFallback(
    RequestOptions options, {
    int? statusCode,
  }) {
    if (options.extra['_browserFallbackRetried'] == true ||
        options.extra['skipBrowserFallback'] == true) {
      return false;
    }

    if (statusCode != 401 && statusCode != 403) {
      return false;
    }

    final host = options.uri.host.trim().toLowerCase();
    final baseHost = Uri.parse(AppConstants.baseUrl).host;
    if (host.isEmpty ||
        (host != baseHost && !host.endsWith('.$baseHost'))) {
      return false;
    }

    final path = options.uri.path;
    return _sensitivePaths.any((pattern) {
      if (pattern is RegExp) return pattern.hasMatch(path);
      return path.contains(pattern.toString());
    });
  }
}
