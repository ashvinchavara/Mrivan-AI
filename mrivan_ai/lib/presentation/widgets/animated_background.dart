import 'dart:ui';
import 'package:flutter/material.dart';

/// AnimatedBackground renders the moving clouds and smooth transition gradient.
/// Can be wrapped around any screen to keep a consistent premium look.
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool isDarkMode;
  final Widget? floatingActionButton;

  const AnimatedBackground({
    super.key,
    required this.child,
    required this.isDarkMode,
    this.floatingActionButton,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with TickerProviderStateMixin {
  late final AnimationController _cloudsController;
  late final AnimationController _themeTransitionController;

  // Cloud configuration coordinates
  late final List<FloatingCloud> _clouds;

  @override
  void initState() {
    super.initState();

    _cloudsController = AnimationController(
      duration: const Duration(seconds: 50),
      vsync: this,
    )..repeat();

    _themeTransitionController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Sync transition with initial theme mode
    if (widget.isDarkMode) {
      _themeTransitionController.value = 1.0;
    }

    _clouds = [
      FloatingCloud(xOffset: -0.2, yOffset: 0.12, speed: 0.015, scale: 1.3, opacity: 0.7),
      FloatingCloud(xOffset: 0.25, yOffset: 0.35, speed: 0.01, scale: 0.9, opacity: 0.5),
      FloatingCloud(xOffset: 0.65, yOffset: 0.18, speed: 0.02, scale: 1.1, opacity: 0.65),
      FloatingCloud(xOffset: 1.05, yOffset: 0.42, speed: 0.008, scale: 1.5, opacity: 0.8),
    ];
  }

  @override
  void didUpdateWidget(covariant AnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDarkMode != oldWidget.isDarkMode) {
      if (widget.isDarkMode) {
        _themeTransitionController.forward();
      } else {
        _themeTransitionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _cloudsController.dispose();
    _themeTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Sky Custom Paint Canvas
        Positioned.fill(
          child: AnimatedBuilder(
            animation: Listenable.merge([_cloudsController, _themeTransitionController]),
            builder: (context, child) {
              return CustomPaint(
                painter: SkyPainter(
                  themeTransition: _themeTransitionController.value,
                  cloudsAnimation: _cloudsController.value,
                  clouds: _clouds,
                ),
              );
            },
          ),
        ),

        // 2. Child Widget Layout (Form/Dashboard content)
        Positioned.fill(
          child: widget.child,
        ),
      ],
    );
  }
}

class FloatingCloud {
  double xOffset;
  final double yOffset;
  final double speed;
  final double scale;
  final double opacity;

  FloatingCloud({
    required this.xOffset,
    required this.yOffset,
    required this.speed,
    required this.scale,
    required this.opacity,
  });
}

class SkyPainter extends CustomPainter {
  final double themeTransition; // 0.0 = Light, 1.0 = Dark
  final double cloudsAnimation;
  final List<FloatingCloud> clouds;

  SkyPainter({
    required this.themeTransition,
    required this.cloudsAnimation,
    required this.clouds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint backgroundPaint = Paint();

    // Lerp background gradients
    final Color topColor = Color.lerp(
      const Color(0xFFD4ECFF),
      const Color(0xFF0F172A),
      themeTransition,
    )!;
    final Color bottomColor = Color.lerp(
      const Color(0xFFFFFFFF),
      const Color(0xFF070512),
      themeTransition,
    )!;

    backgroundPaint.shader = LinearGradient(
      colors: [topColor, bottomColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    // Lerp arch lines
    final Color archColor = Color.lerp(
      const Color(0xFFCBE3FE).withValues(alpha: 0.4),
      Colors.white.withValues(alpha: 0.05),
      themeTransition,
    )!;

    final Paint archPaint = Paint()
      ..color = archColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset(size.width / 2, size.height * 1.05), size.height * 0.55, archPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height * 1.05), size.height * 0.75, archPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height * 1.05), size.height * 0.95, archPaint);

    // Render clouds
    for (var cloud in clouds) {
      final double x = ((cloud.xOffset + cloudsAnimation * cloud.speed * 10) % 1.5 - 0.35) * size.width;
      final double y = cloud.yOffset * size.height;
      _drawCloudShape(canvas, Offset(x, y), cloud.scale, cloud.opacity);
    }
  }

  void _drawCloudShape(Canvas canvas, Offset center, double scale, double opacity) {
    final Color cloudColor = Color.lerp(
      Colors.white.withValues(alpha: opacity * 0.85),
      const Color(0xFF2E384D).withValues(alpha: opacity * 0.55),
      themeTransition,
    )!;

    final Paint cloudPaint = Paint()
      ..color = cloudColor
      ..style = PaintingStyle.fill;

    final double blurSigma = lerpDouble(12.0, 18.0, themeTransition)!;
    cloudPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma * scale);

    final double baseRadius = 35 * scale;
    canvas.drawCircle(center, baseRadius, cloudPaint);
    canvas.drawCircle(center + Offset(-baseRadius * 0.85, baseRadius * 0.15), baseRadius * 0.7, cloudPaint);
    canvas.drawCircle(center + Offset(baseRadius * 0.85, baseRadius * 0.2), baseRadius * 0.65, cloudPaint);
    canvas.drawCircle(center + Offset(-baseRadius * 0.35, -baseRadius * 0.55), baseRadius * 0.85, cloudPaint);
    canvas.drawCircle(center + Offset(baseRadius * 0.45, -baseRadius * 0.45), baseRadius * 0.78, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant SkyPainter oldDelegate) => true;
}
