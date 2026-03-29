import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'cookie/cookie_jar_service.dart';

class BrowserSessionService {
  BrowserSessionService._internal();

  static final BrowserSessionService instance =
      BrowserSessionService._internal();

  static const Set<String> _loginCookieNames = <String>{
    '_t',
    '_forum_session',
    'cf_clearance',
  };

  static const Set<String> _cfCookieNames = <String>{'cf_clearance'};

  final CookieJarService _cookieJar = CookieJarService();

  Future<void> syncLoginBoundary({
    InAppWebViewController? controller,
    String? currentUrl,
  }) async {
    await syncBoundarySession(
      source: 'login_boundary',
      controller: controller,
      currentUrl: currentUrl,
      cookieNames: _loginCookieNames,
    );
  }

  Future<void> syncCfBoundary({
    InAppWebViewController? controller,
    String? currentUrl,
  }) async {
    await syncBoundarySession(
      source: 'cf_boundary',
      controller: controller,
      currentUrl: currentUrl,
      cookieNames: _cfCookieNames,
    );
  }

  Future<void> syncBoundarySession({
    required String source,
    InAppWebViewController? controller,
    String? currentUrl,
    Set<String> cookieNames = _loginCookieNames,
  }) async {
    debugPrint(
      '[BrowserSession] syncBoundarySession source=$source currentUrl=$currentUrl names=${cookieNames.toList(growable: false)}',
    );
    await _cookieJar.syncSessionSnapshotFromWebView(
      currentUrl: currentUrl,
      controller: controller,
      cookieNames: cookieNames,
    );
    await _cookieJar.refreshSessionSnapshot(source: source);
  }

  Future<void> refreshSnapshot({required String source}) {
    return _cookieJar.refreshSessionSnapshot(source: source);
  }
}
