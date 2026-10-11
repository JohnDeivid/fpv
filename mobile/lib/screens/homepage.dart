import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buana_vpad/screens/connect_page.dart';
import 'package:buana_vpad/screens/controller_list_page.dart';
import 'package:buana_vpad/screens/settings_page.dart';
import 'package:buana_vpad/widgets/fpv_drone_3d_viewer.dart';
import 'package:buana_vpad/widgets/fpv_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buana_vpad/enums/link.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _droneController;
  late Animation<double> _droneFloat;
  late Animation<double> _droneRotate;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _droneController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _droneFloat = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _droneController, curve: Curves.easeInOut),
    );

    _droneRotate = Tween<double>(begin: -0.015, end: 0.015).animate(
      CurvedAnimation(parent: _droneController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _droneController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF060A12),
      body: FpvAnimatedBackground(
        child: Stack(
          children: [
            // ── Main scrollable content ───────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Top bar ─────────────────────────────────────
                    _buildTopBar(context),

                    const SizedBox(height: 8),

                    // ── Hero: 3D Model Viewer ────────────────────────
                    _build3DHero(context, size),

                    const SizedBox(height: 28),

                    // ── Section label ────────────────────────────────
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: _SectionLabel(
                          label: 'MY CONTROLLERS', icon: Icons.sports_esports),
                    ),
                    const SizedBox(height: 16),

                    // ── Controller quick-cards ───────────────────────
                    _ControllerQuickList(
                      onOpenAll: () => Navigator.push(
                        context,
                        _route(const ControllerListPage()),
                      ),
                    ),

                    const SizedBox(height: 100), // space for FAB area
                  ],
                ),
              ),
            ),

            // ── Floating Action Menu ─────────────────────────────────
            _buildFloatingMenu(context),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Logo / Brand
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FPV Controller',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'PILOT MODE',
                style: TextStyle(
                  color: const Color(0xFF00D4FF).withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Settings icon — small, Apple-style
          GestureDetector(
            onTap: () => Navigator.push(context, _route(const SettingsPage())),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                  width: 0.8,
                ),
              ),
              child: const Icon(Icons.settings, color: Colors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3D HERO MODEL ─────────────────────────────────────────────────────────
  Widget _build3DHero(BuildContext context, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 28,
        opacity: 0.04,
        borderColor: const Color(0xFF00D4FF).withOpacity(0.15),
        child: Column(
          children: [
            // 3D WebGL Model — gentle float animation via transform on the card
            AnimatedBuilder(
              animation: _droneFloat,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _droneFloat.value * 0.3),
                child: child,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: FpvDrone3dViewer(
                  height: size.height * 0.38,
                  onToggleFullScreen: () => showFpvDrone3dFullScreen(context),
                ),
              ),
            ),

            // Caption bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Row(
                children: [
                  const PillBadge(
                      label: '4K PBR', color: Color(0xFF00D4FF)),
                  const SizedBox(width: 8),
                  const PillBadge(
                      label: 'INTERACTIVE 3D', color: Color(0xFF7B61FF)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => showFpvDrone3dFullScreen(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00D4FF).withOpacity(0.30),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.fullscreen,
                              color: Color(0xFF00D4FF), size: 15),
                          SizedBox(width: 4),
                          Text(
                            'Full View',
                            style: TextStyle(
                              color: Color(0xFF00D4FF),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FLOATING ACTION MENU ──────────────────────────────────────────────────
  Widget _buildFloatingMenu(BuildContext context) {
    return Positioned(
      bottom: 28,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expanded sub-options (visible when _menuOpen)
          AnimatedOpacity(
            opacity: _menuOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedSlide(
              offset: _menuOpen ? Offset.zero : const Offset(0, 0.3),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _FloatingMenuItem(
                    icon: Icons.sports_esports_outlined,
                    label: 'My Controllers',
                    onTap: () {
                      setState(() => _menuOpen = false);
                      Navigator.push(
                          context, _route(const ControllerListPage()));
                    },
                  ),
                  const SizedBox(height: 10),
                  _FloatingMenuItem(
                    icon: Icons.wifi_outlined,
                    label: 'Connect',
                    onTap: () {
                      setState(() => _menuOpen = false);
                      Navigator.push(context, _route(const ConnectPage()));
                    },
                  ),
                  const SizedBox(height: 10),
                  _FloatingMenuItem(
                    icon: Icons.download_outlined,
                    label: 'Get Desktop App',
                    onTap: () {
                      setState(() => _menuOpen = false);
                      _launchUrl(Link.windowsDownload.path);
                    },
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // Main FAB — gamepad icon
          GestureDetector(
            onTap: () => setState(() => _menuOpen = !_menuOpen),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF0085A3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withOpacity(0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: _menuOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(
                  Icons.sports_esports,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PageRoute _route(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}

// ── SUB WIDGETS ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00D4FF), size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

class _FloatingMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FloatingMenuItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.09), width: 0.8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3), blurRadius: 10)
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.09),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.12), width: 0.8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Quick controller cards shown on the home screen
class _ControllerQuickList extends StatelessWidget {
  final VoidCallback onOpenAll;
  const _ControllerQuickList({required this.onOpenAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            onTap: onOpenAll,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFF6B00).withOpacity(0.3),
                        width: 0.8),
                  ),
                  child: const Icon(Icons.flight,
                      color: Color(0xFFFF6B00), size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FPV Mode 2 🚁',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Throttle + Yaw / Pitch + Roll',
                        style:
                            TextStyle(color: Color(0xFF8899AA), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const PillBadge(label: 'FPV', color: Color(0xFFFF6B00)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF445566), size: 18),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            onTap: onOpenAll,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF00D4FF).withOpacity(0.25),
                        width: 0.8),
                  ),
                  child: const Icon(Icons.gamepad_outlined,
                      color: Color(0xFF00D4FF), size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ver todos los mandos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Gestionar layouts personalizados',
                        style:
                            TextStyle(color: Color(0xFF8899AA), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF445566), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
