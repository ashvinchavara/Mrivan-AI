import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// AnimatedBackground renders the moving academic symbols and smooth transition gradient.
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
  late final AnimationController _symbolsController;
  late final AnimationController _themeTransitionController;

  // Symbol configuration coordinates
  late final List<FloatingSymbol> _symbols;

  @override
  void initState() {
    super.initState();

    _symbolsController = AnimationController(
      duration: const Duration(seconds: 40),
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

    _symbols = [
      FloatingSymbol(symbol: '📚', xOffset: -0.1, yOffset: 0.12, speed: 0.012, size: 36, rotationSpeed: 0.08),
      FloatingSymbol(symbol: 'π', xOffset: 0.15, yOffset: 0.24, speed: 0.008, size: 28, rotationSpeed: -0.12),
      FloatingSymbol(symbol: '💡', xOffset: 0.35, yOffset: 0.08, speed: 0.015, size: 32, rotationSpeed: 0.05),
      FloatingSymbol(symbol: 'E=mc²', xOffset: 0.55, yOffset: 0.32, speed: 0.007, size: 22, rotationSpeed: 0.06),
      FloatingSymbol(symbol: '🎓', xOffset: 0.75, yOffset: 0.18, speed: 0.011, size: 38, rotationSpeed: -0.05),
      FloatingSymbol(symbol: '∑', xOffset: 0.95, yOffset: 0.28, speed: 0.014, size: 30, rotationSpeed: 0.10),
      FloatingSymbol(symbol: '⚛️', xOffset: 1.15, yOffset: 0.14, speed: 0.009, size: 34, rotationSpeed: -0.07),
      FloatingSymbol(symbol: 'f(x)', xOffset: 1.35, yOffset: 0.36, speed: 0.013, size: 24, rotationSpeed: 0.04),
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
    _symbolsController.dispose();
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
            animation: Listenable.merge([_symbolsController, _themeTransitionController]),
            builder: (context, child) {
              return CustomPaint(
                painter: StudyThemePainter(
                  themeTransition: _themeTransitionController.value,
                  animationValue: _symbolsController.value,
                  symbols: _symbols,
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

class FloatingSymbol {
  final String symbol;
  double xOffset;
  final double yOffset;
  final double speed;
  final double size;
  final double rotationSpeed;

  FloatingSymbol({
    required this.symbol,
    required this.xOffset,
    required this.yOffset,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
  });
}

class StudyThemePainter extends CustomPainter {
  final double themeTransition; // 0.0 = Light, 1.0 = Dark
  final double animationValue;
  final List<FloatingSymbol> symbols;

  StudyThemePainter({
    required this.themeTransition,
    required this.animationValue,
    required this.symbols,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint backgroundPaint = Paint();

    // Lerp background gradients (Light: Warm vanilla focus, Dark: Cozy slate blue Focus)
    final Color topColor = Color.lerp(
      const Color(0xFFF0F7FF), // Soft focus light blue
      const Color(0xFF0F172A), // Cozy Slate Blue
      themeTransition,
    )!;
    final Color bottomColor = Color.lerp(
      const Color(0xFFFFFBEB), // Warm Ivory
      const Color(0xFF020617), // Deep Library midnight
      themeTransition,
    )!;

    backgroundPaint.shader = LinearGradient(
      colors: [topColor, bottomColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    // Draw Lightbulb (Focus Mode) rising in light mode
    final double bulbX = size.width * 0.82;
    final double bulbY = size.height * (0.2 + 0.35 * themeTransition);
    final double bulbOpacity = (1.0 - themeTransition).clamp(0.0, 1.0);
    _drawLightbulb(canvas, Offset(bulbX, bulbY), bulbOpacity);

    // Draw Graduation Cap (Midnight Mode) glowing in dark mode
    final double capX = size.width * 0.82;
    final double capY = size.height * (0.55 - 0.35 * themeTransition);
    final double capOpacity = themeTransition.clamp(0.0, 1.0);
    _drawGraduationCap(canvas, Offset(capX, capY), capOpacity);

    // Render floating academic symbols
    for (var fs in symbols) {
      final double x = ((fs.xOffset + animationValue * fs.speed * 10) % 1.5 - 0.25) * size.width;
      final double y = fs.yOffset * size.height + (sin(animationValue * 2 * pi + fs.xOffset * 10) * 15);
      final double rotation = animationValue * 2 * pi * fs.rotationSpeed;
      _drawFloatingSymbol(canvas, fs.symbol, Offset(x, y), fs.size, rotation, themeTransition);
    }
  }

  void _drawLightbulb(Canvas canvas, Offset center, double opacity) {
    if (opacity <= 0.0) return;

    final double radius = 26.0;
    final double blurSigma = (1.0 - opacity) * 16.0;
    final bool applyBlur = blurSigma > 0.1;

    if (applyBlur) {
      final Rect bounds = Rect.fromCircle(center: center, radius: radius * 3.5);
      canvas.saveLayer(
        bounds,
        Paint()..imageFilter = ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma, tileMode: TileMode.decal),
      );
    }

    // 1. Bulb glow
    final Paint glowPaint = Paint()
      ..color = Colors.amber.shade200.withValues(alpha: opacity * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35.0);
    canvas.drawCircle(center, radius * 2.2, glowPaint);

    // 2. Outer glass body
    final Paint bulbPaint = Paint()
      ..color = Colors.amber.shade400.withValues(alpha: opacity * 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bulbPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.amber.shade600.withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, borderPaint);

    // 3. Bulb Base (socket)
    final double baseWidth = radius * 0.7;
    final double baseHeight = radius * 0.35;
    final Rect baseRect = Rect.fromCenter(
      center: center + Offset(0, radius + baseHeight / 2 - 2),
      width: baseWidth,
      height: baseHeight,
    );
    final Paint basePaint = Paint()
      ..color = Colors.grey.shade400.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(4)),
      basePaint,
    );

    final Paint baseBorder = Paint()
      ..color = Colors.grey.shade600.withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(4)),
      baseBorder,
    );

    // Thread lines on base
    canvas.drawLine(
      center + Offset(-baseWidth * 0.4, radius + 4),
      center + Offset(baseWidth * 0.4, radius + 4),
      baseBorder,
    );
    canvas.drawLine(
      center + Offset(-baseWidth * 0.4, radius + 8),
      center + Offset(baseWidth * 0.4, radius + 8),
      baseBorder,
    );

    // 4. Filament
    final Paint filamentPaint = Paint()
      ..color = Colors.amber.shade800.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final Path filPath = Path()
      ..moveTo(center.dx - radius * 0.3, center.dy + radius * 0.6)
      ..lineTo(center.dx - radius * 0.15, center.dy - radius * 0.1)
      ..quadraticBezierTo(
        center.dx, center.dy - radius * 0.4,
        center.dx + radius * 0.15, center.dy - radius * 0.1,
      )
      ..lineTo(center.dx + radius * 0.3, center.dy + radius * 0.6);
    canvas.drawPath(filPath, filamentPaint);

    // 5. Radiating Rays
    final Paint rayPaint = Paint()
      ..color = Colors.amber.shade500.withValues(alpha: opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final double rayLen = 12.0;
    final double startDist = radius + 8.0;

    for (int i = 0; i < 8; i++) {
      final double angle = i * pi / 4;
      final double dx = cos(angle);
      final double dy = sin(angle);
      // Skip downward facing rays so it doesn't collide with the base
      if (dy > 0.7) continue;
      canvas.drawLine(
        center + Offset(dx * startDist, dy * startDist),
        center + Offset(dx * (startDist + rayLen), dy * (startDist + rayLen)),
        rayPaint,
      );
    }

    if (applyBlur) {
      canvas.restore();
    }
  }

  void _drawGraduationCap(Canvas canvas, Offset center, double opacity) {
    if (opacity <= 0.0) return;

    final double size = 32.0;
    final double blurSigma = (1.0 - opacity) * 16.0;
    final bool applyBlur = blurSigma > 0.1;

    if (applyBlur) {
      final Rect bounds = Rect.fromCircle(center: center, radius: size * 3.0);
      canvas.saveLayer(
        bounds,
        Paint()..imageFilter = ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma, tileMode: TileMode.decal),
      );
    }

    // 1. Blue/indigo glow
    final Paint glowPaint = Paint()
      ..color = const Color(0xFF155DFC).withValues(alpha: opacity * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25.0);
    canvas.drawCircle(center, size * 2.0, glowPaint);

    // 2. Skull cap (bottom part)
    final Paint capPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF155DFC).withValues(alpha: opacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Path skullCap = Path()
      ..moveTo(center.dx - size * 0.5, center.dy + size * 0.1)
      ..quadraticBezierTo(
        center.dx, center.dy + size * 0.6,
        center.dx + size * 0.5, center.dy + size * 0.1,
      )
      ..lineTo(center.dx + size * 0.5, center.dy + size * 0.3)
      ..quadraticBezierTo(
        center.dx, center.dy + size * 0.8,
        center.dx - size * 0.5, center.dy + size * 0.3,
      )
      ..close();
    canvas.drawPath(skullCap, capPaint);
    canvas.drawPath(skullCap, borderPaint);

    // 3. Mortarboard diamond (top part)
    final Path diamond = Path()
      ..moveTo(center.dx, center.dy - size * 0.5) // Top
      ..lineTo(center.dx + size, center.dy) // Right
      ..lineTo(center.dx, center.dy + size * 0.4) // Bottom
      ..lineTo(center.dx - size, center.dy) // Left
      ..close();

    final Paint diamondPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(diamond, diamondPaint);
    canvas.drawPath(diamond, borderPaint);

    // 4. Button on top
    final Paint buttonPaint = Paint()
      ..color = const Color(0xFF155DFC).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center + Offset(0, -size * 0.05), 4.0, buttonPaint);

    // 5. Tassel
    final Paint tasselPaint = Paint()
      ..color = Colors.amber.shade400.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final Path tassel = Path()
      ..moveTo(center.dx, center.dy - size * 0.05)
      ..quadraticBezierTo(
        center.dx - size * 0.6, center.dy + size * 0.1,
        center.dx - size * 0.8, center.dy + size * 0.5,
      );
    canvas.drawPath(tassel, tasselPaint);

    // Tassel fringe/brush
    final Paint brushPaint = Paint()
      ..color = Colors.amber.shade500.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center + Offset(-size * 0.8, size * 0.5), 3.0, brushPaint);

    if (applyBlur) {
      canvas.restore();
    }
  }

  void _drawFloatingSymbol(Canvas canvas, String symbol, Offset position, double size, double rotation, double themeTransition) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: Color.lerp(
            const Color(0xFF155DFC).withValues(alpha: 0.14),
            Colors.cyanAccent.withValues(alpha: 0.14),
            themeTransition,
          ),
          shadows: themeTransition > 0.1
              ? [
                  Shadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.15 * themeTransition),
                    blurRadius: 8.0,
                  )
                ]
              : null,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StudyThemePainter oldDelegate) => true;
}
