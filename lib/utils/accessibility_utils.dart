import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// 접근성 개선을 위한 유틸리티 클래스
class AccessibilityUtils {
  /// 최소 터치 타겟 크기 (44x44 dp)
  static const double minTouchTargetSize = 44.0;

  /// 권장 색상 대비율 (WCAG AA 기준)
  static const double recommendedContrastRatio = 4.5;

  /// 터치 타겟 크기를 확인하고 조정하는 위젯
  static Widget ensureTouchTarget({
    required Widget child,
    VoidCallback? onTap,
    String? semanticLabel,
    String? tooltip,
  }) {
    return SizedBox(
      width: minTouchTargetSize,
      height: minTouchTargetSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(minTouchTargetSize / 2),
          child: Semantics(
            label: semanticLabel,
            button: onTap != null,
            child: Tooltip(
              message: tooltip ?? '',
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  /// 스크린 리더를 위한 의미 있는 라벨 생성
  static String generateSemanticLabel({
    required String title,
    String? subtitle,
    String? status,
    String? action,
  }) {
    final parts = <String>[title];
    
    if (subtitle != null && subtitle.isNotEmpty) {
      parts.add(subtitle);
    }
    
    if (status != null && status.isNotEmpty) {
      parts.add('상태: $status');
    }
    
    if (action != null && action.isNotEmpty) {
      parts.add('동작: $action');
    }
    
    return parts.join(', ');
  }

  /// 색상 대비율 계산
  static double calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();
    
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 색상 대비율이 충분한지 확인
  static bool hasGoodContrast(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= recommendedContrastRatio;
  }

  /// 접근성을 고려한 색상 조정
  static Color adjustColorForContrast(Color foreground, Color background) {
    if (hasGoodContrast(foreground, background)) {
      return foreground;
    }
    
    // 배경색의 밝기에 따라 전경색 조정
    final backgroundLuminance = background.computeLuminance();
    
    if (backgroundLuminance > 0.5) {
      // 밝은 배경 -> 어두운 전경
      return Colors.black87;
    } else {
      // 어두운 배경 -> 밝은 전경
      return Colors.white;
    }
  }
}

/// 접근성이 향상된 버튼 위젯
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor;
    final fgColor = foregroundColor ?? 
        AccessibilityUtils.adjustColorForContrast(
          theme.primaryTextTheme.labelLarge?.color ?? Colors.white,
          bgColor,
        );

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: bgColor,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            child: Container(
              padding: padding,
              constraints: const BoxConstraints(
                minWidth: AccessibilityUtils.minTouchTargetSize,
                minHeight: AccessibilityUtils.minTouchTargetSize,
              ),
              child: DefaultTextStyle(
                style: TextStyle(color: fgColor),
                child: IconTheme(
                  data: IconThemeData(color: fgColor),
                  child: Center(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 접근성이 향상된 카드 위젯
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? tooltip;
  final EdgeInsets margin;
  final EdgeInsets padding;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.tooltip,
    this.margin = const EdgeInsets.all(8),
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: Tooltip(
          message: tooltip ?? '',
          child: Card(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: padding,
                constraints: onTap != null ? const BoxConstraints(
                  minHeight: AccessibilityUtils.minTouchTargetSize,
                ) : null,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 접근성이 향상된 텍스트 필드
class AccessibleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final String? semanticLabel;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int? maxLines;

  const AccessibleTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.semanticLabel,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? labelText,
      textField: true,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

/// 진행률을 접근성 친화적으로 표시하는 위젯
class AccessibleProgressIndicator extends StatelessWidget {
  final double value;
  final String? label;
  final String? semanticLabel;
  final Color? color;
  final Color? backgroundColor;

  const AccessibleProgressIndicator({
    super.key,
    required this.value,
    this.label,
    this.semanticLabel,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).round();
    final accessibleLabel = semanticLabel ?? 
        '${label ?? '진행률'}: $percentage 퍼센트';

    return Semantics(
      label: accessibleLabel,
      value: percentage.toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
          ],
          LinearProgressIndicator(
            value: value,
            color: color,
            backgroundColor: backgroundColor,
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage%',
            style: Theme.of(context).textTheme.bodySmall,
            semanticsLabel: null, // 이미 위에서 제공됨
          ),
        ],
      ),
    );
  }
}

/// 접근성 설정을 확인하는 유틸리티
class AccessibilityChecker {
  /// 현재 접근성 설정 확인
  static AccessibilityFeatures getCurrentAccessibilityFeatures(BuildContext context) {
    return MediaQuery.of(context).accessibilityFeatures;
  }

  /// 스크린 리더 사용 여부 확인
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// 고대비 모드 사용 여부 확인
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// 텍스트 크기 배율 확인
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  /// 접근성 권장사항 검사
  static List<String> checkAccessibilityIssues(
    BuildContext context, {
    Color? foregroundColor,
    Color? backgroundColor,
    double? fontSize,
    String? text,
  }) {
    final issues = <String>[];

    // 색상 대비 검사
    if (foregroundColor != null && backgroundColor != null) {
      if (!AccessibilityUtils.hasGoodContrast(foregroundColor, backgroundColor)) {
        issues.add('색상 대비가 부족합니다. (권장: 4.5:1 이상)');
      }
    }

    // 텍스트 크기 검사
    if (fontSize != null && fontSize < 14) {
      issues.add('텍스트 크기가 너무 작습니다. (권장: 14sp 이상)');
    }

    // 텍스트 내용 검사
    if (text != null && text.trim().isEmpty) {
      issues.add('의미 있는 텍스트가 필요합니다.');
    }

    return issues;
  }
}
