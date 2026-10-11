import 'dart:ui';
import 'package:flutter/material.dart';

/// Animated background with subtle particle sweep and dark aesthetic.
/// Pure monochrome: deep blacks, dark slate, subtle white accents. ZERO BLUE.
class FpvAnimatedBackground extends StatefulWidget {
  final Widget child;
  const FpvAnimatedBackground({super.key, required this.child});

  @override
  State<FpvAnimatedBackground> createState() => _FpvAnimatedBackgroundState();
}

class _FpvAnimatedBackgroundState extends State<FpvAnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pitch black to deep dark charcoal gradient
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, 0),
              radius: 1.4,
              colors: [
                Color(0xFF141414),
                Color(0xFF080808),
                Color(0xFF000000),
              ],
              stops: [0.0, 0.65, 1.0],
            ),
          ),
        ),

        // Subtle fine grid pattern in white with very low opacity
        CustomPaint(
          size: Size.infinite,
          painter: _GridPainter(),
        ),

        // Subtle ambient center halo
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) {
            final opacity = 0.02 + _pulseController.value * 0.025;
            return Center(
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(opacity),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Subtle horizontal scanline pass
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
                height: 1.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.06),
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
      ..color = Colors.white.withOpacity(0.018)
      ..strokeWidth = 0.5;

    const step = 48.0;
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

/// Glassmorphic frosted card with real backdrop filter blur.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double opacity;
  final double blur;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.opacity = 0.06,
    this.blur = 16.0,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withOpacity(0.08),
            highlightColor: Colors.white.withOpacity(0.04),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white.withOpacity(opacity),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor ?? Colors.white.withOpacity(0.12),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimalist pill badge with monochrome styling
class PillBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const PillBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: c.withOpacity(0.85)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: c.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted capsule bar with 5 dots loader / signal indicator.
/// Animates signal wave pulses and indicates connected / scanning state.
class SignalDotsBar extends StatefulWidget {
  final int activeCount;
  final bool isScanning;
  final VoidCallback? onTap;

  const SignalDotsBar({
    super.key,
    this.activeCount = 3,
    this.isScanning = true,
    this.onTap,
  });

  @override
  State<SignalDotsBar> createState() => _SignalDotsBarState();
}

class _SignalDotsBarState extends State<SignalDotsBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x33141414),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    double dotOpacity;
                    if (widget.isScanning) {
                      // Wave animation from left to right across 5 dots
                      final wavePos = (_animController.value * 5);
                      final dist = (wavePos - index).abs();
                      if (dist < 1.2) {
                        dotOpacity = 0.95 - (dist * 0.45);
                      } else {
                        dotOpacity = 0.22;
                      }
                    } else {
                      dotOpacity = index < widget.activeCount ? 0.95 : 0.22;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
                        width: index == 1 && !widget.isScanning ? 7 : 6,
                        height: index == 1 && !widget.isScanning ? 7 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(dotOpacity.clamp(0.18, 1.0)),
                          boxShadow: dotOpacity > 0.7
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
