import 'package:flutter/material.dart';

/// Animated background with floating particles and diagonal scan lines
/// giving an FPV HUD / cinematic feel.
class FpvAnimatedBackground extends StatefulWidget {
  final Widget child;
  const FpvAnimatedBackground({super.key, required this.child});

  @override
  State<FpvAnimatedBackground> createState() => _FpvAnimatedBackgroundState();
}

class _FpvAnimatedBackgroundState extends State<FpvAnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _rotateController;
  late final AnimationController _pulseController;
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Deep space gradient base
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.5,
              colors: [
                Color(0xFF0D1B2A),
                Color(0xFF060A12),
                Color(0xFF020508),
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        ),

        // Subtle grid pattern
        CustomPaint(
          size: Size.infinite,
          painter: _GridPainter(),
        ),

        // Rotating halo behind 3D model area
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) {
            final opacity = 0.04 + _pulseController.value * 0.04;
            return Positioned(
              top: -80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF00D4FF).withOpacity(opacity),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Scan line sweep
        AnimatedBuilder(
          animation: _scanController,
          builder: (_, __) {
            final h = MediaQuery.of(context).size.height;
            final y = _scanController.value * h * 1.2 - h * 0.1;
            return Positioned(
              top: y,
              left: 0,
              right: 0,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF00D4FF).withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Main content
        widget.child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.025)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

/// Glassmorphic card — frosted glass on the dark FPV background
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double opacity;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.opacity = 0.07,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: const Color(0xFF00D4FF).withOpacity(0.08),
          highlightColor: const Color(0xFF00D4FF).withOpacity(0.04),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.10),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Small pill badge — for labels like "FPV", "Game", "BETA"
class PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  const PillBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
