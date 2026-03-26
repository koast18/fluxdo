import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'network/cookie/cookie_jar_service.dart';
import 'network/cookie/cookie_write_through.dart';

/// 迁移项定义
class _Migration {
  const _Migration({
    required this.key,
    required this.name,
    required this.shouldRun,
    required this.run,
  });

  /// SharedPreferences 标记键
  final String key;

  /// 迁移名称（日志用）
  final String name;

  /// 前置检查：返回 true 才真正执行迁移
  /// 全新安装时应返回 false（没有旧数据需要迁移）
  final Future<bool> Function() shouldRun;

  /// 执行迁移的函数
  final Future<void> Function() run;
}

/// 统一迁移服务
/// 新增迁移只需在 [_migrations] 列表末尾追加一条即可。
class MigrationService {
  MigrationService._();

  /// 本次启动是否执行了迁移（供 UI 展示用）
  static bool didMigrate = false;

  /// 按顺序执行的迁移列表
  static final _migrations = <_Migration>[
    // v1: Cookie write-through 迁移
    // 清理旧 syncToWebView 写入的 cookie（缺少 SameSite 等属性），用新机制重新注入
    _Migration(
      key: 'cookie_write_through_migration_v1',
      name: 'Cookie write-through',
      shouldRun: () async {
        // CookieJar 中有 _t（登录 token）才需要迁移（说明是老用户升级）
        final jar = CookieJarService();
        if (!jar.isInitialized) await jar.initialize();
        final token = await jar.getTToken();
        return token != null && token.isNotEmpty;
      },
      run: () async {
        final jar = CookieJarService();
        if (!jar.isInitialized) await jar.initialize();

        for (final name in const ['_t', '_forum_session', 'cf_clearance']) {
          await jar.deleteWebViewCookie(name);
        }
        await CookieWriteThrough.instance.seedCriticalCookies();
      },
    ),
  ];

  /// 在 main() 中调用，在所有网络服务启动之前执行
  static Future<void> runAll(SharedPreferences prefs) async {
    didMigrate = false;

    for (final m in _migrations) {
      if (prefs.getBool(m.key) == true) continue;

      if (!await m.shouldRun()) {
        await prefs.setBool(m.key, true);
        debugPrint('[Migration] 跳过（无需迁移）: ${m.name}');
        continue;
      }

      debugPrint('[Migration] 开始: ${m.name}');
      try {
        await m.run();
        await prefs.setBool(m.key, true);
        didMigrate = true;
        debugPrint('[Migration] 完成: ${m.name}');
      } catch (e) {
        debugPrint('[Migration] 失败: ${m.name}, $e');
      }
    }
  }
}
