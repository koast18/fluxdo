import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/// 桌面窗口状态持久化服务
///
/// 保存/恢复窗口的大小、位置和最大化状态。
/// 通过 [startListening] 监听窗口变化并自动保存（防抖 500ms）。
class WindowStateService with WindowListener {
  WindowStateService._();
  static final WindowStateService instance = WindowStateService._();

  static const _kX = 'window_x';
  static const _kY = 'window_y';
  static const _kW = 'window_w';
  static const _kH = 'window_h';
  static const _kMaximized = 'window_maximized';

  SharedPreferences? _prefs;
  Timer? _saveTimer;

  /// 恢复上次保存的窗口状态并显示窗口
  Future<void> restore(SharedPreferences prefs) async {
    _prefs = prefs;

    final isMaximized = prefs.getBool(_kMaximized) ?? false;
    final w = prefs.getDouble(_kW);
    final h = prefs.getDouble(_kH);
    final x = prefs.getDouble(_kX);
    final y = prefs.getDouble(_kY);

    if (w != null && h != null) {
      await windowManager.setSize(Size(w, h));
    }
    if (x != null && y != null) {
      await windowManager.setPosition(Offset(x, y));
    }
    if (isMaximized) {
      await windowManager.maximize();
    }
    await windowManager.show();
  }

  /// 开始监听窗口变化
  void startListening() {
    windowManager.addListener(this);
  }

  /// 停止监听并清理资源
  void stopListening() {
    _saveTimer?.cancel();
    windowManager.removeListener(this);
  }

  /// 立即保存当前窗口状态
  Future<void> save() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final isMaximized = await windowManager.isMaximized();
    await prefs.setBool(_kMaximized, isMaximized);
    // 最大化时不覆盖尺寸和位置，恢复时使用最大化前的值
    if (!isMaximized) {
      final size = await windowManager.getSize();
      final pos = await windowManager.getPosition();
      await prefs.setDouble(_kW, size.width);
      await prefs.setDouble(_kH, size.height);
      await prefs.setDouble(_kX, pos.dx);
      await prefs.setDouble(_kY, pos.dy);
    }
  }

  /// 防抖保存
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), save);
  }

  @override
  void onWindowResized() => _scheduleSave();

  @override
  void onWindowMoved() => _scheduleSave();

  @override
  void onWindowMaximize() => _scheduleSave();

  @override
  void onWindowUnmaximize() => _scheduleSave();

  @override
  void onWindowClose() async {
    _saveTimer?.cancel();
    await save();
    if (Platform.isMacOS) {
      // macOS: 隐藏窗口而不是销毁，Dock 图标可以重新唤起
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }
}
