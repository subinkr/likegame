import 'package:flutter/material.dart';
import 'dart:async';

/// 성능 최적화를 위한 유틸리티 클래스
class PerformanceUtils {
  /// 디바운스 기능을 제공하는 클래스
  static Map<String, Timer?> _timers = {};

  /// 디바운스된 함수 실행
  /// [key] - 고유 키
  /// [duration] - 지연 시간
  /// [callback] - 실행할 함수
  static void debounce(String key, Duration duration, VoidCallback callback) {
    _timers[key]?.cancel();
    _timers[key] = Timer(duration, callback);
  }

  /// 쓰로틀링된 함수 실행
  /// [key] - 고유 키
  /// [duration] - 최소 간격
  /// [callback] - 실행할 함수
  static void throttle(String key, Duration duration, VoidCallback callback) {
    if (_timers[key]?.isActive != true) {
      callback();
      _timers[key] = Timer(duration, () {});
    }
  }

  /// 모든 타이머 정리
  static void dispose() {
    for (final timer in _timers.values) {
      timer?.cancel();
    }
    _timers.clear();
  }

  /// 특정 키의 타이머 정리
  static void disposeKey(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
  }
}

/// 메모화를 위한 믹스인
mixin MemoizationMixin<T extends StatefulWidget> on State<T> {
  final Map<String, dynamic> _cache = {};

  /// 값을 메모화
  R memoize<R>(String key, R Function() computation) {
    if (_cache.containsKey(key)) {
      return _cache[key] as R;
    }
    final result = computation();
    _cache[key] = result;
    return result;
  }

  /// 캐시 무효화
  void invalidateCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }

  @override
  void dispose() {
    _cache.clear();
    super.dispose();
  }
}

/// 성능 최적화된 리스트 아이템 위젯
class OptimizedListItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool addRepaintBoundary;
  final bool addAutomaticKeepAlive;

  const OptimizedListItem({
    super.key,
    required this.child,
    this.onTap,
    this.addRepaintBoundary = true,
    this.addAutomaticKeepAlive = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget item = child;

    if (addAutomaticKeepAlive) {
      item = KeepAliveHelper.wrapWidget(item);
    }

    if (addRepaintBoundary) {
      item = RepaintBoundary(child: item);
    }

    if (onTap != null) {
      item = InkWell(
        onTap: onTap,
        child: item,
      );
    }

    return item;
  }
}

/// AutomaticKeepAlive를 위한 헬퍼
class KeepAliveHelper {
  static Widget wrapWidget(Widget child) {
    return _KeepAliveWrapper(child: child);
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// 성능 최적화된 빌더 위젯
class OptimizedBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final List<Object?> dependencies;
  final bool shouldRebuild;

  const OptimizedBuilder({
    super.key,
    required this.builder,
    this.dependencies = const [],
    this.shouldRebuild = true,
  });

  @override
  State<OptimizedBuilder> createState() => _OptimizedBuilderState();
}

class _OptimizedBuilderState extends State<OptimizedBuilder> {
  Widget? _cachedWidget;
  List<Object?> _lastDependencies = [];

  @override
  Widget build(BuildContext context) {
    if (!widget.shouldRebuild && _cachedWidget != null) {
      return _cachedWidget!;
    }

    // 의존성이 변경되지 않았다면 캐시된 위젯 반환
    if (_cachedWidget != null && 
        _listEquals(widget.dependencies, _lastDependencies)) {
      return _cachedWidget!;
    }

    // 새로운 위젯 빌드 및 캐시
    _cachedWidget = widget.builder(context);
    _lastDependencies = List.from(widget.dependencies);
    
    return _cachedWidget!;
  }

  bool _listEquals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 성능 모니터링을 위한 위젯
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String name;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    required this.name,
    this.enabled = true,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  int _buildCount = 0;
  DateTime? _lastBuildTime;

  @override
  Widget build(BuildContext context) {
    if (widget.enabled) {
      _buildCount++;
      final now = DateTime.now();
      if (_lastBuildTime != null) {
        final timeSinceLastBuild = now.difference(_lastBuildTime!);
      }
      _lastBuildTime = now;
    }

    return widget.child;
  }
}

/// 지연 로딩을 위한 위젯
class LazyWidget extends StatefulWidget {
  final Widget Function() builder;
  final Widget? placeholder;
  final Duration delay;

  const LazyWidget({
    super.key,
    required this.builder,
    this.placeholder,
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> {
  Widget? _builtWidget;
  bool _isBuilding = false;

  @override
  void initState() {
    super.initState();
    _scheduleBuilder();
  }

  void _scheduleBuilder() {
    if (_isBuilding) return;
    
    _isBuilding = true;
    Future.delayed(widget.delay, () {
      if (mounted && _builtWidget == null) {
        setState(() {
          _builtWidget = widget.builder();
          _isBuilding = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _builtWidget ?? 
           widget.placeholder ?? 
           const SizedBox.shrink();
  }
}


