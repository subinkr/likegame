import 'package:flutter/material.dart';

/// 애니메이션 관련 유틸리티 클래스
class AnimationUtils {
  /// 표준 애니메이션 지속시간
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  /// 표준 커브
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve bounceIn = Curves.bounceIn;

  /// 페이드 인 애니메이션
  static Widget fadeIn({
    required Widget child,
    Duration duration = mediumDuration,
    Curve curve = standardCurve,
    double? delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: delay != null 
        ? DelayedWidget(delay: Duration(milliseconds: (delay * 1000).toInt()), child: child)
        : child,
    );
  }

  /// 슬라이드 인 애니메이션
  static Widget slideIn({
    required Widget child,
    Duration duration = mediumDuration,
    Curve curve = standardCurve,
    Offset begin = const Offset(0, 1),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(
            value.dx * MediaQuery.of(context).size.width,
            value.dy * MediaQuery.of(context).size.height,
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  /// 스케일 인 애니메이션
  static Widget scaleIn({
    required Widget child,
    Duration duration = mediumDuration,
    Curve curve = standardCurve,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 회전 애니메이션
  static Widget rotateIn({
    required Widget child,
    Duration duration = mediumDuration,
    Curve curve = standardCurve,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159, // 2π 라디안
          child: child,
        );
      },
      child: child,
    );
  }

  /// 페이지 전환 애니메이션
  static PageRouteBuilder<T> createPageRoute<T>({
    required Widget page,
    PageTransitionType type = PageTransitionType.slideFromRight,
    Duration duration = mediumDuration,
    Curve curve = standardCurve,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case PageTransitionType.fade:
            return FadeTransition(opacity: animation, child: child);
          
          case PageTransitionType.slideFromRight:
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: curve)),
              ),
              child: child,
            );
          
          case PageTransitionType.slideFromLeft:
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: curve)),
              ),
              child: child,
            );
          
          case PageTransitionType.slideFromBottom:
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                    .chain(CurveTween(curve: curve)),
              ),
              child: child,
            );
          
          case PageTransitionType.scale:
            return ScaleTransition(
              scale: animation.drive(
                Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
              ),
              child: child,
            );
          
          case PageTransitionType.rotation:
            return RotationTransition(
              turns: animation.drive(
                Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
              ),
              child: child,
            );
        }
      },
    );
  }
}

/// 페이지 전환 타입
enum PageTransitionType {
  fade,
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  scale,
  rotation,
}

/// 지연 위젯
class DelayedWidget extends StatefulWidget {
  final Duration delay;
  final Widget child;

  const DelayedWidget({
    super.key,
    required this.delay,
    required this.child,
  });

  @override
  State<DelayedWidget> createState() => _DelayedWidgetState();
}

class _DelayedWidgetState extends State<DelayedWidget> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _show = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _show ? widget.child : const SizedBox.shrink();
  }
}

/// 스태거드 애니메이션을 위한 위젯
class StaggeredAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final StaggerType type;

  const StaggeredAnimation({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 100),
    this.duration = AnimationUtils.mediumDuration,
    this.curve = AnimationUtils.standardCurve,
    this.type = StaggerType.fadeIn,
  });

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final delay = widget.delay.inMilliseconds * index / 1000.0;

        switch (widget.type) {
          case StaggerType.fadeIn:
            return AnimationUtils.fadeIn(
              child: child,
              duration: widget.duration,
              curve: widget.curve,
              delay: delay,
            );
          
          case StaggerType.slideIn:
            return AnimationUtils.slideIn(
              child: child,
              duration: widget.duration,
              curve: widget.curve,
            );
          
          case StaggerType.scaleIn:
            return AnimationUtils.scaleIn(
              child: child,
              duration: widget.duration,
              curve: widget.curve,
            );
        }
      }).toList(),
    );
  }
}

/// 스태거드 애니메이션 타입
enum StaggerType {
  fadeIn,
  slideIn,
  scaleIn,
}

/// 애니메이션된 카운터 위젯
class AnimatedCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = AnimationUtils.mediumDuration,
    this.style,
    this.prefix,
    this.suffix,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _updateAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _updateAnimation();
      _controller.reset();
      _controller.forward();
    }
  }

  void _updateAnimation() {
    _animation = IntTween(
      begin: _previousValue,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix ?? ''}${_animation.value}${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}

/// 물결 애니메이션 위젯
class RippleAnimation extends StatefulWidget {
  final Widget child;
  final Color color;
  final Duration duration;
  final double minRadius;
  final double maxRadius;

  const RippleAnimation({
    super.key,
    required this.child,
    this.color = Colors.blue,
    this.duration = const Duration(seconds: 2),
    this.minRadius = 0,
    this.maxRadius = 100,
  });

  @override
  State<RippleAnimation> createState() => _RippleAnimationState();
}

class _RippleAnimationState extends State<RippleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.minRadius,
      end: widget.maxRadius,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: _animation.value * 2,
              height: _animation.value * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(
                  1.0 - (_animation.value / widget.maxRadius),
                ),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

/// 펄스 애니메이션 위젯
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 1),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
