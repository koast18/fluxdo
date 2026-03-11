import 'dart:async';
import 'package:flutter/material.dart';

import 'package:paper_shaders/paper_shaders.dart';

import '../services/apk_download_service.dart';
import '../services/update_service.dart';

/// 下载进度对话框
class DownloadProgressDialog extends StatefulWidget {
  final ApkAsset asset;
  final ApkDownloadService downloadService;

  const DownloadProgressDialog({
    super.key,
    required this.asset,
    required this.downloadService,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  StreamSubscription<ApkDownloadProgress>? _subscription;
  ApkDownloadProgress _progress = ApkDownloadProgress(
    status: ApkDownloadStatus.idle,
  );
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startDownload() {
    _subscription = widget.downloadService
        .downloadAndInstall(widget.asset)
        .listen(
      (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _isRetrying = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _progress = ApkDownloadProgress(
              status: ApkDownloadStatus.error,
              error: error.toString(),
            );
            _isRetrying = false;
          });
        }
      },
    );
  }

  void _retry() {
    setState(() {
      _isRetrying = true;
      _progress = ApkDownloadProgress(status: ApkDownloadStatus.idle);
    });
    _subscription?.cancel();
    _startDownload();
  }

  void _cancel() {
    widget.downloadService.cancelDownload();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const double dialogWidth = 300;
    const double dialogHeight = 340;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: Stack(
            children: [
              // 1. MeshGradient 动态背景
              Positioned.fill(
                child: _buildMeshBackground(context),
              ),
              
              // 2. 内容层
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    
                    // 核心进度展示
                    _buildMainProgress(),
                    
                    const SizedBox(height: 32),
                    
                    // 状态描述
                    _buildStatusText(),

                     const Spacer(),

                    // 底部操作
                     _buildBottomAction(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeshBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MeshGradient(
      colors: [
        colorScheme.primary,
        colorScheme.secondary,
        colorScheme.tertiary,
        colorScheme.inversePrimary,
      ],
      distortion: 0.8,
      swirl: 0.1,
      speed: 1,
    );
  }

  // 辅助方法：获取当前主题下的高对比度颜色
  Color get _contentColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : const Color(0xFF1e293b); // Slate 800
  }

  Color get _subContentColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white70 : const Color(0xFF64748b); // Slate 500
  }

  Widget _buildMainProgress() {
    final status = _progress.status;
    final color = _contentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (status == ApkDownloadStatus.downloading) {
        return Column(
          children: [
             Text(
                '${_progress.progress.toInt()}%',
                style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w300, 
                    color: color,
                    height: 1.0,
                    fontFamily: 'monospace', 
                ),
            ),
            const SizedBox(height: 16),
            // 极简线条进度条
            LinearProgressIndicator(
              value: _progress.progress / 100,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 2, 
              borderRadius: BorderRadius.circular(1),
            ),
          ],
        );
    } else if (status == ApkDownloadStatus.verifying || status == ApkDownloadStatus.idle) {
         return SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
        );
    } else {
        IconData icon;
        Color iconColor = color;
        
        switch (status) {
            case ApkDownloadStatus.installing:
                icon = Icons.install_mobile_outlined;
                break;
            case ApkDownloadStatus.completed:
                icon = Icons.check_circle_outline;
                break;
            case ApkDownloadStatus.error:
                icon = Icons.error_outline;
                // 深色模式下错误用白色，浅色模式下可以用红色或者深色
                // 这里为了保持极简，统一跟随主色，或者错误时稍微明显一点
                iconColor = isDark ? Colors.white : Colors.red.shade700;
                break;
            default:
                icon = Icons.download;
        }

        return Icon(icon, size: 72, color: iconColor);
    }
  }

  Widget _buildStatusText() {
    return Text(
      _getStatusText(),
       textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: _subContentColor,
        letterSpacing: 0.5,
      ),
    );
  }

  String _getStatusText() {
    switch (_progress.status) {
      case ApkDownloadStatus.idle:
        return '正在连接...';
      case ApkDownloadStatus.downloading:
        return '正在下载 ${widget.asset.name}';
      case ApkDownloadStatus.verifying:
        return '正在校验文件...';
      case ApkDownloadStatus.installing:
        return '正在安装...';
      case ApkDownloadStatus.completed:
        return '已开始安装';
      case ApkDownloadStatus.error:
        return _progress.error ?? '发生错误';
    }
  }

  Widget _buildBottomAction() {
    final status = _progress.status;
    final color = _contentColor;
    final subColor = _subContentColor;

    if (status == ApkDownloadStatus.error) {
         return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: subColor),
              child: const Text('关闭'),
            ),
            const SizedBox(width: 16),
             TextButton(
              onPressed: _isRetrying ? null : _retry,
               style: TextButton.styleFrom(foregroundColor: color),
              child: const Text('重试'),
            ),
          ],
        );
    }

    if (status == ApkDownloadStatus.completed || status == ApkDownloadStatus.installing) {
         return TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: subColor),
            child: const Text('关闭'),
        );
    }

    // 下载中
    return TextButton(
        onPressed: _cancel,
        style: TextButton.styleFrom(
            foregroundColor: subColor.withValues(alpha: 0.5), // 弱化取消
        ),
        child: const Text('取消'),
    );
  }
}