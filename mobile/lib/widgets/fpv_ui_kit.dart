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
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withOpacity(0.12),
            highlightColor: Colors.white.withOpacity(0.06),
            child: Container(
              decoration: BoxDecoration(
                // Liquid glass translucency (mostly transparent, not black carbon)
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
                    blurRadius: 20,
                    offset: const Offset(0, 6),
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

/// White button with 3 diagonal transparent stripes as requested by the user.
/// Aesthetic: pure white, 3 slashes cut across, labeled "CONECTAR".
class StripedConnectButton extends StatelessWidget {
  final VoidCallback onTap;

  const StripedConnectButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The 3 diagonal transparent stripes drawn on the right side
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
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: 20), // breathing room for the 3 diagonal stripes
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
