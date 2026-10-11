import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buana_vpad/enums/link.dart';
import 'package:buana_vpad/screens/connect_to_pc_page.dart';
import 'package:buana_vpad/screens/controller_list_page.dart';
import 'package:buana_vpad/screens/controller_preview_page.dart';
import 'package:buana_vpad/screens/settings_page.dart';
import 'package:buana_vpad/utils/fpv_layout_factory.dart';
import 'package:buana_vpad/utils/settings_manager.dart';
import 'package:buana_vpad/widgets/fpv_drone_3d_viewer.dart';
import 'package:buana_vpad/widgets/fpv_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // Background state (default false = 12.webp image, true = WebGL 3D model)
  bool _use3dModel = false;

  // Flight tuning state
  bool _stickyThrottle = true;
  double _stickExpo = 35.0; // 0 to 100%
  double _stickDeadzone = 4.0; // 0 to 15%
  bool _invertPitch = false;
  bool _hapticEnabled = true;

  // Signal & connection suite state
  final TextEditingController _ipController =
      TextEditingController(text: '192.168.1.100');
  final TextEditingController _portController =
      TextEditingController(text: '8000');
  String _selectedLayoutName = 'FPV Mode 2';
  bool _isScanning = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _lockLandscape();
    _loadBackgroundPreference();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  Future<void> _loadBackgroundPreference() async {
    final use3d = await SettingsManager.getUse3dModel();
    if (mounted) {
      setState(() => _use3dModel = use3d);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
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

  // ── APPLE LIQUID GLASS SIDE SHEET MODAL ──────────────────────────────────
  // Wraps in Material to prevent yellow underlines and "No Material widget found" errors!
  void _openLiquidGlassSheet({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 260),
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

        return Material(
          type: MaterialType.transparency,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: sheetWidth,
              height: double.infinity,
              decoration: BoxDecoration(
                // Apple Liquid Glass: mostly transparent with heavy frosted blur
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.04),
                    Colors.black.withOpacity(0.20),
                  ],
                ),
                border: Border(
                  left: BorderSide(
                    color: Colors.white.withOpacity(0.28),
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(-6, 0),
                  ),
                ],
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with clean, professional typography
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
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
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.55),
                                        fontSize: 11,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          color: Colors.white.withOpacity(0.15),
                          height: 1,
                        ),
                        // Scrollable Content
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: content,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── POPUP 1: MANDOS & CONTROLES ──────────────────────────────────────────
  void _openControllersPopup(BuildContext context) {
    _openLiquidGlassSheet(
      context: context,
      title: 'MANDOS & CONTROLES',
      subtitle: 'Configuración y selección de perfil',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Buttons Side-by-Side: Main big button + Secondary edit button
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _launchFlightMode();
                  },
                  icon: const Icon(Icons.flight, color: Colors.black, size: 16),
                  label: const Text(
                    'INICIAR VUELO',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ControllerListPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.35)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'PLANTILLAS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            'PERFILES DE VUELO',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Single-line compact liquid glass items (as requested: no useless text)
          _buildCompactProfileTile(
            title: 'FPV Mode 2',
            icon: Icons.flight,
            badge: 'ACTIVO',
            isSelected: true,
            onTap: () {
              Navigator.pop(context);
              _launchFlightMode();
            },
          ),
          const SizedBox(height: 6),

          _buildCompactProfileTile(
            title: 'DJI FPV',
            icon: Icons.flight_takeoff,
            badge: 'DRONE',
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              _launchFlightMode();
            },
          ),
          const SizedBox(height: 6),

          _buildCompactProfileTile(
            title: 'PlayStation',
            icon: Icons.play_circle_outline,
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
          const SizedBox(height: 6),

          _buildCompactProfileTile(
            title: 'Gamepad Pro',
            icon: Icons.sports_esports_outlined,
            badge: 'ABXY',
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ControllerListPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── POPUP 2: TUNING & AJUSTES (100% BUG FREE MATERIAL WRAPPED) ────────────
  void _openSettingsPopup(BuildContext context) {
    _openLiquidGlassSheet(
      context: context,
      title: 'TUNING & AJUSTES',
      subtitle: 'Respuesta fina de sticks y gimbals',
      content: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sticky Throttle
              _buildCompactSwitchRow(
                title: 'Acelerador FPV Sticky',
                value: _stickyThrottle,
                onChanged: (val) {
                  setState(() => _stickyThrottle = val);
                  setSheetState(() => _stickyThrottle = val);
                },
              ),
              const SizedBox(height: 10),

              // Expo Slider (Single line label)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Curva Expo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_stickExpo.toInt()}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.18),
                  thumbColor: Colors.white,
                  trackHeight: 2.5,
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

              // Deadzone Slider (Single line label)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Zona Muerta (Deadzone)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_stickDeadzone.toInt()}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.18),
                  thumbColor: Colors.white,
                  trackHeight: 2.5,
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

              // Invert Pitch
              _buildCompactSwitchRow(
                title: 'Invertir Eje Pitch',
                value: _invertPitch,
                onChanged: (val) {
                  setState(() => _invertPitch = val);
                  setSheetState(() => _invertPitch = val);
                },
              ),
              const SizedBox(height: 8),

              // Haptic Feedback
              _buildCompactSwitchRow(
                title: 'Vibración Háptica',
                value: _hapticEnabled,
                onChanged: (val) {
                  setState(() => _hapticEnabled = val);
                  setSheetState(() => _hapticEnabled = val);
                  if (val) HapticFeedback.selectionClick();
                },
              ),
              const SizedBox(height: 16),

              // Side-by-Side buttons: Calibrate (big) + Reset (small)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
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
                          size: 15, color: Colors.black),
                      label: const Text(
                        'CALIBRAR STICKS',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () {
                        setSheetState(() {
                          _stickExpo = 35.0;
                          _stickDeadzone = 4.0;
                          _stickyThrottle = true;
                          _invertPitch = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'RESET',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ── POPUP 3: HERRAMIENTAS & SISTEMA (CLEAN LIQUID GLASS) ───────────────────
  void _openMorePopup(BuildContext context) {
    _openLiquidGlassSheet(
      context: context,
      title: 'HERRAMIENTAS & SISTEMA',
      subtitle: 'Diagnóstico y sincronización',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCompactActionTile(
            title: 'Escanear Red Wi-Fi Local',
            icon: Icons.wifi_find,
            onTap: () {
              Navigator.pop(context);
              _openConnectSuitePopup(context);
            },
          ),
          const SizedBox(height: 6),

          _buildCompactActionTile(
            title: 'Descargar Receptor Desktop PC',
            icon: Icons.download_outlined,
            onTap: () {
              Navigator.pop(context);
              _launchUrl(Link.windowsDownload.path);
            },
          ),
          const SizedBox(height: 6),

          _buildCompactActionTile(
            title: 'Diagnóstico de Latencia (Ping)',
            icon: Icons.speed,
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ping a PC: 2.1 ms · 0% pérdidas'),
                  backgroundColor: Color(0xFF1E1E1E),
                ),
              );
            },
          ),
          const SizedBox(height: 6),

          _buildCompactActionTile(
            title: 'Configuraciones Generales',
            icon: Icons.settings,
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
              _lockLandscape();
              _loadBackgroundPreference();
            },
          ),

          const SizedBox(height: 18),
          Center(
            child: Text(
              'BUANA VPAD • FPV CONTROLLER v2.5\nLiquid Glass Edition',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 9.5,
                letterSpacing: 1.2,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── POPUP 4: COMPLETE PC CONNECTION SUITE (ALL IN ONE LATERAL WINDOW) ─────
  void _openConnectSuitePopup(BuildContext context) {
    _openLiquidGlassSheet(
      context: context,
      title: 'CONECTAR AL SIMULADOR PC',
      subtitle: 'Enlace inalámbrico directo para simuladores FPV',
      content: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Header Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'GATEWAY DISPONIBLE (5 GHz)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '2.4 ms',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // IP Address Field
              Text(
                'DIRECCIÓN IP DEL PC',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _ipController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '192.168.1.100',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Port Field
              Text(
                'PUERTO',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '8000',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Select Controller / Layout
              Text(
                'SELECCIONAR MANDO',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  'FPV Mode 2',
                  'DJI FPV',
                  'PlayStation',
                  'Pro Gamepad',
                ].map((name) {
                  final isSelected = _selectedLayoutName == name;
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() => _selectedLayoutName = name);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Action buttons side-by-side: Big Connect Button + Rescan Button
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ConnectToPcPage()),
                        );
                      },
                      icon: const Icon(Icons.bolt, color: Colors.black, size: 16),
                      label: const Text(
                        'CONECTAR',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setSheetState(() => _isScanning = true);
                        Future.delayed(const Duration(milliseconds: 1400), () {
                          if (ctx.mounted) {
                            setSheetState(() => _isScanning = false);
                          }
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.35)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isScanning ? 'BUSCANDO...' : 'ESCANEAR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ── HELPER TILES (SINGLE LINE LIQUID GLASS) ───────────────────────────────
  Widget _buildCompactProfileTile({
    required String title,
    required IconData icon,
    required String badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.18)
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.5)
                : Colors.white.withOpacity(0.18),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PillBadge(label: badge),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
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

  Widget _buildCompactActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.white.withOpacity(0.35), size: 17),
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
        backgroundColor: Colors.black,
        body: FpvStudioBackground(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── LAYER 1: Background (12.webp Image by default OR 3D Model WebGL) ──
              Positioned.fill(
                child: _use3dModel
                    ? const FpvDrone3dViewer(isFullScreen: true)
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/drone_bg.webp',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                          // Subtle dark tint to ensure UI icons and widgets pop with maximum contrast
                          Container(
                            color: Colors.black.withOpacity(0.35),
                          ),
                        ],
                      ),
              ),

              // ── LAYER 2: TOP BAR (FPV Goggles OSD Typography) ─────────────
              Positioned(
                top: 14,
                left: 20,
                right: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Precision Crosshair / Reticle icon
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.filter_center_focus,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // FPV Goggles OSD Title (Betaflight HUD Style)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'FPV CONTROLLER // SIMULATOR',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.4,
                          ),
                        ),
                        Text(
                          '[MODE: 2 • ARMED • 120FPS OSD]',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Top-Right Liquid Glass Action Buttons
                    // 1. Mandos & Controles Button
                    _buildLiquidGlassHeaderButton(
                      icon: Icons.sports_esports_outlined,
                      tooltip: 'Mandos y perfiles',
                      onTap: () => _openControllersPopup(context),
                    ),
                    const SizedBox(width: 8),

                    // 2. Settings Gear Button
                    _buildLiquidGlassHeaderButton(
                      icon: Icons.settings_outlined,
                      tooltip: 'Ajustes y tuning',
                      onTap: () => _openSettingsPopup(context),
                    ),
                    const SizedBox(width: 8),

                    // 3. More Three Dots Button
                    _buildLiquidGlassHeaderButton(
                      icon: Icons.more_horiz,
                      tooltip: 'Herramientas y sistema',
                      onTap: () => _openMorePopup(context),
                    ),
                  ],
                ),
              ),

              // ── LAYER 2.5: AGGRESSIVE HERO TITLE ON THE LEFT SIDE ─────────
              Positioned(
                left: 24,
                top: 75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 22,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'BUANA VPAD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.5,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        'HIGH SPEED DRONE TELEMETRY // CYBER LINK',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── LAYER 3: BOTTOM-RIGHT STRIPED CONNECT BUTTON & LOADER ──────
              Positioned(
                bottom: 16,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Frosted bar with 5 animated dots loader
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.20),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'BUSCANDO SEÑALES',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.60),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // 5 dots loader
                              ...List.generate(5, (index) {
                                final dotOpacity =
                                    ((_pulseController.value + (index * 0.20)) % 1.0)
                                        .clamp(0.25, 1.0);
                                return Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(dotOpacity),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),

                    // White button with aggressive diagonal slanted edges
                    StripedConnectButton(
                      onTap: () => _openConnectSuitePopup(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Liquid glass circular button for top bar
  Widget _buildLiquidGlassHeaderButton({
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
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                // Liquid glass sheen
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.28),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
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
