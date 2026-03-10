import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/read_later_provider.dart';
import 'read_later_sheet.dart';

/// 稍后阅读浮窗气泡
/// 提取自 DraggableFloatingPill 的拖拽/吸附核心算法
class ReadLaterBubble extends ConsumerStatefulWidget {
  const ReadLaterBubble({super.key});

  @override
  ConsumerState<ReadLaterBubble> createState() => _ReadLaterBubbleState();
}

class _ReadLaterBubbleState extends ConsumerState<ReadLaterBubble>
    with TickerProviderStateMixin {
  static const double _bubbleSize = 48.0;
  static const double _overlap = 16.0;

  late AnimationController _controller;
  late Animation<Offset> _animation;

  Offset _offset = Offset.zero;
  // ignore: unused_field
  bool _isDragging = false; // 预留：用于拖拽状态判断
  bool _isAdsorbed = false;
  bool _isInitialized = false;
  bool _isSheetOpen = false;
  late Size _screenSize;

  bool get _isRightSide => _offset.dx > (_screenSize.width / 2);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.addListener(() {
      setState(() {
        _offset = _animation.value;
      });
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAdsorbed = true;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
    if (_offset == Offset.zero) {
      // 初始化到右下角
      final topPadding = MediaQuery.of(context).padding.top;
      _offset = Offset(
        _screenSize.width,
        _screenSize.height * 0.7 + topPadding,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target = _calculateTargetPosition(Offset.zero);
        setState(() {
          _offset = target;
          _isAdsorbed = true;
          _isInitialized = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _controller.stop();
    if (_isAdsorbed) {
      final screenWidth = _screenSize.width;
      double currentLeft;
      if (_isRightSide) {
        currentLeft = screenWidth - _bubbleSize + _overlap;
      } else {
        currentLeft = -_overlap;
      }
      setState(() {
        _offset = Offset(currentLeft, _offset.dy);
        _isDragging = true;
        _isAdsorbed = false;
      });
    } else {
      setState(() {
        _isDragging = true;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    _animateToEdge(details.velocity.pixelsPerSecond);
  }

  Offset _calculateTargetPosition(Offset velocity) {
    final double screenWidth = _screenSize.width;
    final currentCenterX = _offset.dx + _bubbleSize / 2;

    double targetX;
    if (currentCenterX < screenWidth / 2) {
      targetX = -_overlap;
    } else {
      targetX = screenWidth - _bubbleSize + _overlap;
    }

    double targetY = _offset.dy;
    final double topPadding = MediaQuery.of(context).padding.top + 50;
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    if (targetY < topPadding) targetY = topPadding;
    if (targetY > _screenSize.height - _bubbleSize - bottomPadding) {
      targetY = _screenSize.height - _bubbleSize - bottomPadding;
    }

    return Offset(targetX, targetY);
  }

  void _animateToEdge(Offset velocity) {
    final target = _calculateTargetPosition(velocity);
    _animation = Tween<Offset>(
      begin: _offset,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward(from: 0);
  }

  void _handleTap() async {
    setState(() => _isSheetOpen = true);
    await ReadLaterSheet.show();
    if (mounted) {
      setState(() => _isSheetOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appReady = ref.watch(appReadyProvider);
    final items = ref.watch(readLaterProvider);

    // 应用未就绪、列表为空、或面板已打开时不显示
    if (!appReady || items.isEmpty || _isSheetOpen) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = colorScheme.inverseSurface;
    final contentColor = colorScheme.onInverseSurface;

    final bool isRight = _isRightSide;

    double? left, right, top;
    top = _offset.dy;

    if (_isAdsorbed) {
      if (isRight) {
        right = -_overlap;
        left = null;
      } else {
        left = -_overlap;
        right = null;
      }
    } else {
      left = _offset.dx;
      right = null;
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      child: Opacity(
        opacity: _isInitialized ? 1.0 : 0.0,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onTap: _handleTap,
          child: Container(
            width: _bubbleSize,
            height: _bubbleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor.withValues(alpha: 0.9),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 图标
                Center(
                  child: Icon(
                    Icons.layers,
                    size: 22,
                    color: contentColor,
                  ),
                ),
                // 数量角标
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '${items.length}',
                        style: TextStyle(
                          color: colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
