import 'dart:io' as io;

import 'package:flutter/foundation.dart';

import 'cookie_value_codec.dart';

/// App 热路径使用的关键会话快照。
///
/// 只保存登录态关键 cookie，避免每次请求都跨平台读取浏览器 cookie store。
class SessionSnapshot {
  const SessionSnapshot({
    required this.cookies,
    required this.updatedAt,
    required this.source,
  });

  factory SessionSnapshot.empty() => SessionSnapshot(
        cookies: const <String, String>{},
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        source: 'empty',
      );

  final Map<String, String> cookies;
  final DateTime updatedAt;
  final String source;

  String? operator [](String name) => cookies[name];

  bool get hasAuthState =>
      (cookies['_t']?.isNotEmpty ?? false) ||
      (cookies['_forum_session']?.isNotEmpty ?? false);
}

class SessionSnapshotService {
  SessionSnapshotService._internal();

  static final SessionSnapshotService instance =
      SessionSnapshotService._internal();

  static const Set<String> _criticalNames = <String>{
    '_t',
    '_forum_session',
    'cf_clearance',
  };

  SessionSnapshot _snapshot = SessionSnapshot.empty();

  SessionSnapshot get current => _snapshot;

  String? getCookieValue(String name) => _snapshot[name];

  void clear({String source = 'clear'}) {
    _snapshot = SessionSnapshot(
      cookies: const <String, String>{},
      updatedAt: DateTime.now(),
      source: source,
    );
    debugPrint('[SessionSnapshot] cleared by $source');
  }

  void replaceFromCookies(
    Iterable<io.Cookie> cookies, {
    required String source,
  }) {
    final next = <String, String>{};
    for (final cookie in cookies) {
      if (!_criticalNames.contains(cookie.name)) continue;
      if (_isDeleted(cookie)) continue;
      final value = CookieValueCodec.decode(cookie.value);
      if (value.isEmpty) continue;
      next[cookie.name] = value;
    }
    _snapshot = SessionSnapshot(
      cookies: Map.unmodifiable(next),
      updatedAt: DateTime.now(),
      source: source,
    );
    debugPrint(
      '[SessionSnapshot] replace source=$source keys=${next.keys.toList(growable: false)}',
    );
  }

  void mergeFromCookies(
    Iterable<io.Cookie> cookies, {
    required String source,
  }) {
    final next = Map<String, String>.from(_snapshot.cookies);
    var touched = false;
    for (final cookie in cookies) {
      if (!_criticalNames.contains(cookie.name)) continue;
      touched = true;
      if (_isDeleted(cookie)) {
        next.remove(cookie.name);
        continue;
      }
      final value = CookieValueCodec.decode(cookie.value);
      if (value.isEmpty) {
        next.remove(cookie.name);
      } else {
        next[cookie.name] = value;
      }
    }

    if (!touched) return;
    _snapshot = SessionSnapshot(
      cookies: Map.unmodifiable(next),
      updatedAt: DateTime.now(),
      source: source,
    );
    debugPrint(
      '[SessionSnapshot] merge source=$source keys=${next.keys.toList(growable: false)}',
    );
  }

  bool _isDeleted(io.Cookie cookie) {
    final expired =
        cookie.expires != null && cookie.expires!.isBefore(DateTime.now());
    return cookie.value.isEmpty || cookie.value == 'del' || expired;
  }
}
