import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buana_vpad/enums/link.dart';
import 'package:buana_vpad/screens/connect_page.dart';
import 'package:buana_vpad/screens/connect_to_pc_page.dart';
import 'package:buana_vpad/screens/controller_list_page.dart';
import 'package:buana_vpad/screens/controller_preview_page.dart';
import 'package:buana_vpad/screens/settings_page.dart';
import 'package:buana_vpad/utils/fpv_layout_factory.dart';
import 'package:buana_vpad/widgets/fpv_drone_3d_viewer.dart';
import 'package:buana_vpad/widgets/fpv_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Flight settings state (controllable via frosted tuning popup)
  bool _stickyThrottle = true;
  double _stickExpo = 35.0; // 0 to 100%
  double _stickDeadzone = 4.0; // 0 to 15%
  bool _invertPitch = false;
  bool _hapticEnabled = true;

  // Signal scanner loader state
  bool _isScanningSignals = false;
  int _activeSignalDots = 4;
  String _detectedHost = '192.168.1.105:8000';
  bool _pcDetected = true;

  @override
  void initState() {
    super.initState();
    _lockLandscape();
  }

  void _lockLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lockLandscape();
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  void _triggerSignalScan() {
    setState(() {
      _isScanningSignals = true;
    });
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _isScanningSignals = false;
          _activeSignalDots = 5;
          _pcDetected = true;
        });
      }
    });
  }

  Future<void> _launchFlightMode() async {
    final size = MediaQuery.of(context).size;
    final w = math.max(size.width, size.height);
    final h = math.min(size.width, size.height);

    final fpvLayout =
        FpvLayoutFactory.createFpvMode2Layout(screenWidth: w, screenHeight: h);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ControllerPreviewPage(initialLayout: fpvLayout),
      ),
    );
    _lockLandscape();
  }

  // ── POPUPS: FROSTED GLASS SIDE SHEETS (UNDER 50% WIDTH, ONE-HAND OPERATION) ──
  void _openFrostedSideSheet({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, anim, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));

        return SlideTransition(
          position: slide,
          child: child,
        );
      },
      pageBuilder: (ctx, _, __) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final sheetWidth = math.min(screenWidth * 0.46, 420.0);

        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: sheetWidth,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xF2080808),
              border: Border(
                left: BorderSide(
                  color: Colors.white.withOpacity(0.12),
                  width: 1.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 32,
                  offset: const Offset(-8, 0),
                ),
              ],
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.45),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white70, size: 20),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: Colors.white.withOpacity(0.08),
                        height: 1,
                      ),
                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          child: content,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── POPUP 1: CONTROLLERS & PROFILES ───────────────────────────────────────
  void _openControllersPopup(BuildContext context) {
    _openFrostedSideSheet(
      context: context,
      title: 'MANDOS & PERFILES',
      subtitle: 'Selección de transmisor y modo de vuelo',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary Action Button: INICIAR VUELO
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _launchFlightMode();
            },
            icon: const Icon(Icons.flight, color: Colors.black, size: 18),
            label: const Text(
              'INICIAR VUELO MODE 2',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'PERFILES PRECONFIGURADOS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Option 1: FPV Drone Mode 2
          _buildProfileTile(
            title: 'FPV Racing Quad (Mode 2)',
            subtitle: 'Throttle + Yaw / Pitch + Roll',
            icon: Icons.flight,
            badge: 'ACTIVO',
            isSelected: true,
            onTap: () {
              Navigator.pop(context);
              _launchFlightMode();
            },
          ),
          const SizedBox(height: 8),

          // Option 2: DJI Cinewhoop
          _buildProfileTile(
            title: 'DJI Cinewhoop',
            subtitle: 'Curvas suaves para filmación aérea',
            icon: Icons.flight_takeoff,
            badge: 'DRONE',
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              _launchFlightMode();
            },
          ),
          const SizedBox(height: 8),

          // Option 3: PlayStation DualSense
          _buildProfileTile(
            title: 'PlayStation DualSense',
            subtitle: 'Cruceta, gatillos L2/R2 y sticks gemelos',
            icon: Icons.play_circle_outline,
            badge: 'PLAY',
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ControllerListPage()),
              );
            },
          ),
          const SizedBox(height: 8),

          // Option 4: Pro Gamepad
          _buildProfileTile(
            title: 'Arcade / Pro Gamepad',
            subtitle: 'Botones ABXY y distribución clásica',
            icon: Icons.sports_esports_outlined,
            badge: 'PAD',
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ControllerListPage()),
              );
            },
          ),

          const SizedBox(height: 20),
          // Manage layouts button
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ControllerListPage()),
              );
            },
            icon: const Icon(Icons.tune, color: Colors.white, size: 16),
            label: const Text(
              'Gestionar & Crear Plantillas',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── POPUP 2: FPV TUNING & SYSTEM SETTINGS ─────────────────────────────────
  void _openSettingsPopup(BuildContext context) {
    _openFrostedSideSheet(
      context: context,
      title: 'TUNING & CONFIGURACIÓN',
      subtitle: 'Ajustes finos manipulables con una sola mano',
      content: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'AJUSTES DE VUELO FPV',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // Throttle Sticky toggle
              _buildSwitchRow(
                title: 'Acelerador FPV (Throttle Sticky)',
                subtitle: 'No regresa al centro verticalmente (Acro)',
                value: _stickyThrottle,
                onChanged: (val) {
                  setState(() => _stickyThrottle = val);
                  setSheetState(() => _stickyThrottle = val);
                },
              ),
              const SizedBox(height: 14),

              // Stick Expo Slider
              Text(
                'Sensibilidad Expo: ${_stickExpo.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Suaviza el control en el centro del stick',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 11,
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.15),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.1),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: _stickExpo,
                  min: 0,
                  max: 100,
                  onChanged: (val) {
                    setState(() => _stickExpo = val);
                    setSheetState(() => _stickExpo = val);
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Deadzone Slider
              Text(
                'Zona Muerta (Deadzone): ${_stickDeadzone.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Elimina el temblor o drift involuntario',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 11,
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.15),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.1),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: _stickDeadzone,
                  min: 0,
                  max: 15,
                  onChanged: (val) {
                    setState(() => _stickDeadzone = val);
                    setSheetState(() => _stickDeadzone = val);
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Invert Pitch
              _buildSwitchRow(
                title: 'Invertir Eje Pitch (Cabeceo)',
                subtitle: 'Hacia arriba = picar morro (Avión)',
                value: _invertPitch,
                onChanged: (val) {
                  setState(() => _invertPitch = val);
                  setSheetState(() => _invertPitch = val);
                },
              ),
              const SizedBox(height: 12),

              // Haptic Feedback
              _buildSwitchRow(
                title: 'Vibración Háptica',
                subtitle: 'Feedback táctil al mover los sticks',
                value: _hapticEnabled,
                onChanged: (val) {
                  setState(() => _hapticEnabled = val);
                  setSheetState(() => _hapticEnabled = val);
                  if (val) HapticFeedback.lightImpact();
                },
              ),

              const SizedBox(height: 20),
              Text(
                'ENLACE & GATEWAY PC',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi, color: Colors.white70, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gateway PC Destino',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            _detectedHost,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ConnectToPcPage()),
                        );
                      },
                      child: const Text('Cambiar',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Stick calibration button
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sticks calibrados al centro (0.0, 0.0)'),
                      backgroundColor: Color(0xFF1E1E1E),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.filter_center_focus,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Calibrar Centro de Sticks',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── POPUP 3: MORE OPTIONS & TOOLS ─────────────────────────────────────────
  void _openMorePopup(BuildContext context) {
    _openFrostedSideSheet(
      context: context,
      title: 'HERRAMIENTAS & SISTEMA',
      subtitle: 'Acciones rápidas, descargas y visor 3D',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Option: 3D Full Screen
          _buildActionCard(
            title: 'Inspeccionar 3D Pantalla Completa',
            subtitle: 'Gira y analiza el dron y la RadioMaster TX12',
            icon: Icons.fullscreen,
            onTap: () {
              Navigator.pop(context);
              showFpvDrone3dFullScreen(context);
            },
          ),
          const SizedBox(height: 10),

          // Option: Signal scan
          _buildActionCard(
            title: 'Escanear Red Wi-Fi Local',
            subtitle: 'Detecta automáticamente servidores de simulador PC',
            icon: Icons.wifi_find,
            onTap: () {
              Navigator.pop(context);
              _triggerSignalScan();
            },
          ),
          const SizedBox(height: 10),

          // Option: Get desktop app
          _buildActionCard(
            title: 'Descargar App Desktop para PC',
            subtitle: 'Receptor virtual vX360 para Liftoff / Uncrashed',
            icon: Icons.download_outlined,
            onTap: () {
              Navigator.pop(context);
              _launchUrl(Link.windowsDownload.path);
            },
          ),
          const SizedBox(height: 10),

          // Option: Latency Ping Test
          _buildActionCard(
            title: 'Diagnóstico de Latencia (Ping)',
            subtitle: 'Promedio actual: 2.8 ms (Óptimo para carreras FPV)',
            icon: Icons.speed,
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ping a PC: 2.4 ms · 0 paquetes perdidos'),
                  backgroundColor: Color(0xFF1E1E1E),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Option: System Settings
          _buildActionCard(
            title: 'Configuraciones Generales',
            subtitle: 'Nombre de dispositivo, ID y licencias',
            icon: Icons.settings,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),

          const SizedBox(height: 24),
          // App version badge
          Center(
            child: Text(
              'BUANA VPAD • FPV PILOT PRO v2.5\nPure Monochrome Glass Edition',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
                letterSpacing: 1.0,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── POPUP 4: SIGNALS & QUICK CONNECT (TAPPING THE 5 DOTS) ─────────────────
  void _openSignalsPopup(BuildContext context) {
    _openFrostedSideSheet(
      context: context,
      title: 'SEÑALES & CONEXIÓN',
      subtitle: 'Estado del enlace inalámbrico con el PC',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connection strength card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _pcDetected ? Colors.white : Colors.white30,
                        boxShadow: _pcDetected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _pcDetected
                          ? 'SEÑAL ENCONTRADA (5/5 PUNTOS)'
                          : 'ESCANEANDO RED...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '98% CALIDAD',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 5 dots visual status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final isActive = index < _activeSignalDots;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.2),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.4),
                                    blurRadius: 6,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detected host info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.computer, color: Colors.white70, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Simulador PC (Desktop vX360)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_detectedHost · Latencia: 2.4 ms',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // Connect Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConnectToPcPage()),
              );
            },
            icon: const Icon(Icons.link, color: Colors.black, size: 18),
            label: const Text(
              'CONECTAR AL SIMULADOR PC',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Rescan button
          OutlinedButton.icon(
            onPressed: () {
              _triggerSignalScan();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
            label: const Text(
              'Re-escanear Red',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPER WIDGETS FOR POPUPS ─────────────────────────────────────────────
  Widget _buildProfileTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.4)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.0 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      PillBadge(label: badge),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.chevron_right,
              color: isSelected ? Colors.white : Colors.white24,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.5),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.white.withOpacity(0.25), size: 18),
          ],
        ),
      ),
    );
  }

  // ── MAIN LANDSCAPE BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _lockLandscape();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── LAYER 1: Fallback Ambient Backdrop ────────────────────────────
            Container(
              color: const Color(0xFF050505),
              child: CustomPaint(
                painter: _CenterGridReticlePainter(),
                size: Size.infinite,
              ),
            ),

            // ── LAYER 2: Real 3D Model WebGL Canvas (FPV Drone & Transmitter) ─
            const Positioned.fill(
              child: FpvDrone3dViewer(
                showHeader: false,
                isFullScreen: true,
              ),
            ),

            // ── LAYER 3: TOP BAR OVERLAY (Exact match to reference photo) ─────
            Positioned(
              top: 14,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Precision Reticle / Crosshair Icon
                  const Icon(
                    Icons.filter_center_focus,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),

                  // Brand & Mode
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'FPV Controller',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'PILOT MODE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Frosted Badge: [ ⛶ 3D FPV MODEL • PBR 4K ]
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.view_in_ar,
                                size: 12, color: Colors.white.withOpacity(0.8)),
                            const SizedBox(width: 5),
                            Text(
                              '3D FPV MODEL • PBR 4K',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Top-Right Frosted Action Buttons
                  // 1. Gamepad Button
                  _buildHeaderCircleButton(
                    icon: Icons.sports_esports_outlined,
                    tooltip: 'Mandos y perfiles',
                    onTap: () => _openControllersPopup(context),
                  ),
                  const SizedBox(width: 10),

                  // 2. Settings Gear Button
                  _buildHeaderCircleButton(
                    icon: Icons.settings_outlined,
                    tooltip: 'Ajustes y tuning',
                    onTap: () => _openSettingsPopup(context),
                  ),
                  const SizedBox(width: 10),

                  // 3. More Three Dots Button
                  _buildHeaderCircleButton(
                    icon: Icons.more_horiz,
                    tooltip: 'Herramientas y opciones',
                    onTap: () => _openMorePopup(context),
                  ),
                ],
              ),
            ),

            // ── LAYER 4: BOTTOM CENTER SIGNAL LOADER BAR (5 DOTS) ─────────────
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: SignalDotsBar(
                  activeCount: _activeSignalDots,
                  isScanning: _isScanningSignals,
                  onTap: () => _openSignalsPopup(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER CIRCLE BUTTON ──────────────────────────────────────────────────
  Widget _buildHeaderCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fallback subtle center reticle painter for ambient dark depth
class _CenterGridReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 0.5;

    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
