import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Studio background with a faint textured wall and a soft overhead warm light
/// behind the 3D model, as requested.
class FpvStudioBackground extends StatelessWidget {
  final Widget child;
  const FpvStudioBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base dark floor/wall
        Container(color: const Color(0xFF030303)),

        // Faint industrial studio wall texture (vertical seam lines)
        CustomPaint(
          size: Size.infinite,
          painter: _StudioWallPainter(),
        ),

        // Overhead soft warm spotlight hitting from top-center
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.95),
                radius: 1.35,
                colors: [
                  Color(0x38FFA654), // Soft warm golden glow
                  Color(0x16FF9433),
                  Color(0x05FF8800),
                  Colors.transparent,
                ],
                stops: [0.0, 0.35, 0.70, 1.0],
              ),
            ),
          ),
        ),

        // Ambient floor vignette
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.85),
                ],
                stops: const [0.4, 0.8, 1.0],
              ),
            ),
          ),
        ),

        // Foreground content
        child,
      ],
    );
  }
}

class _StudioWallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1.0;

    // Draw faint vertical wall panel seams
    const step = 90.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.75), linePaint);
    }

    // Faint horizontal baseline seam
    final seamPaint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), seamPaint);
  }

  @override
  bool shouldRepaint(_StudioWallPainter oldDelegate) => false;
}

/// Apple Liquid Glass card: transparent with heavy frosted blur and crisp borders.
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        // Slightly reduced blur so background details stay crisp and modern
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withOpacity(0.12),
            highlightColor: Colors.white.withOpacity(0.06),
            child: Container(
              decoration: BoxDecoration(
                // Liquid glass translucency
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.24),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
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

/// Apple Liquid Glass pill badge
class PillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;

  const PillBadge({
    super.key,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slanted aggressive button: Left and right edges cut in diagonal (parallelogram / cyber style),
/// pure white fill, sharp military FPV look with 3 diagonal stripes.
class StripedConnectButton extends StatelessWidget {
  final VoidCallback onTap;

  const StripedConnectButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double slant = 14.0;
    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: _SlantedParallelogramClipper(slant: slant),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The 3 diagonal transparent stripes
              Positioned.fill(
                child: CustomPaint(
                  painter: _ThreeDiagonalStripesPainter(),
                ),
              ),

              // Button label and connection icon
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.power_settings_new,
                    color: Colors.black,
                    size: 17,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'CONECTAR',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                  SizedBox(width: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clips a rectangular button into an aggressive slanted parallelogram:
/// Both left and right borders slant diagonally to the right (slanted edges).
class _SlantedParallelogramClipper extends CustomClipper<Path> {
  final double slant;
  const _SlantedParallelogramClipper({this.slant = 14.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(slant, 0); // top-left slanted right
    path.lineTo(size.width, 0); // top-right
    path.lineTo(size.width - slant, size.height); // bottom-right slanted right
    path.lineTo(0, size.height); // bottom-left
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_SlantedParallelogramClipper oldClipper) => oldClipper.slant != slant;
}

/// Draws 3 diagonal transparent stripes across the right portion of the button
class _ThreeDiagonalStripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stripePaint = Paint()
      ..color = Colors.black.withOpacity(0.18) // semi-transparent cut
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    final startX = size.width - 24;
    for (int i = 0; i < 3; i++) {
      final x = startX + (i * 6.5);
      canvas.drawLine(
        Offset(x, 4),
        Offset(x - 8, size.height - 4),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ThreeDiagonalStripesPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// GlassCard — Liquid glass card for secondary screens (settings, connect, etc.)
// ─────────────────────────────────────────────────────────────────────────────

/// Frosted glass card widget used across secondary screens.
/// Supports optional tap, custom padding, border radius, and border color.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = borderColor ?? Colors.white.withOpacity(0.18);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withOpacity(0.10),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.10),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: effectiveBorder,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
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

// ─────────────────────────────────────────────────────────────────────────────
// FpvAnimatedBackground — Animated dark studio background for secondary screens
// Uses the same studio wall aesthetic but with a subtle continuous animation.
// ─────────────────────────────────────────────────────────────────────────────

class FpvAnimatedBackground extends StatefulWidget {
  final Widget child;
  const FpvAnimatedBackground({super.key, required this.child});

  @override
  State<FpvAnimatedBackground> createState() => _FpvAnimatedBackgroundState();
}

class _FpvAnimatedBackgroundState extends State<FpvAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Base deep black
            Container(color: const Color(0xFF030303)),

            // Animated warm spotlight from the top
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(_ctrl.value * math.pi * 2) * 0.10,
                      -0.90,
                    ),
                    radius: 1.2 + (_ctrl.value * 0.15),
                    colors: [
                      Color.fromRGBO(255, 165, 80,
                          0.20 + (_ctrl.value * 0.08)),
                      Color.fromRGBO(255, 130, 40, 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Bottom vignette
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.80),
                    ],
                    stops: const [0.45, 0.80, 1.0],
                  ),
                ),
              ),
            ),

            // Subtle studio wall lines
            CustomPaint(
              size: Size.infinite,
              painter: _AnimatedWallPainter(_ctrl.value),
            ),

            // Foreground
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _AnimatedWallPainter extends CustomPainter {
  final double t;
  const _AnimatedWallPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.018 + t * 0.008)
      ..strokeWidth = 1.0;

    const step = 90.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.72), linePaint);
    }

    final seamPaint = Paint()
      ..color = Colors.white.withOpacity(0.030)
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(0, size.height * 0.72),
        Offset(size.width, size.height * 0.72),
        seamPaint);
  }

  @override
  bool shouldRepaint(_AnimatedWallPainter old) => old.t != t;
}
