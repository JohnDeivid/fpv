import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buana_vpad/database/db_helper.dart';
import 'package:buana_vpad/models/controller_layout.dart';
import 'package:buana_vpad/screens/controller_preview_page.dart';
import 'package:buana_vpad/utils/fpv_layout_factory.dart';
import 'package:buana_vpad/widgets/fpv_drone_3d_viewer.dart';
import 'package:buana_vpad/widgets/fpv_ui_kit.dart';

// ── Controller template definitions using clean vector icons (NO URL/Browser images) ──
class _ControllerTemplate {
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;

  const _ControllerTemplate({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
  });
}

const _kTemplates = [
  _ControllerTemplate(
    title: 'FPV Drone Mode 2',
    subtitle: 'Throttle + Yaw / Pitch + Roll · Acro & Angle',
    tag: 'FPV',
    icon: Icons.flight,
  ),
  _ControllerTemplate(
    title: 'DJI Drone Controller',
    subtitle: 'Cinewhoop & Camera Drone Layout',
    tag: 'DRONE',
    icon: Icons.flight_takeoff,
  ),
  _ControllerTemplate(
    title: 'PlayStation DualSense',
    subtitle: 'PlayStation D-pad, Triggers & ABXY',
    tag: 'PLAY',
    icon: Icons.play_circle_outline,
  ),
  _ControllerTemplate(
    title: 'Pro Gamepad',
    subtitle: 'Xbox / Generic Twin-Stick Gamepad',
    tag: 'PAD',
    icon: Icons.sports_esports_outlined,
  ),
];

class ControllerListPage extends StatefulWidget {
  const ControllerListPage({super.key});

  @override
  State<ControllerListPage> createState() => _ControllerListPageState();
}

class _ControllerListPageState extends State<ControllerListPage> {
  final dbHelper = DatabaseHelper();
  bool isLoading = true;
  List<ControllerLayout> layouts = [];

  @override
  void initState() {
    super.initState();
    _lockLandscape();
    _loadLayouts();
  }

  void _lockLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void deactivate() {
    _lockLandscape();
    super.deactivate();
  }

  Future<void> _loadLayouts() async {
    setState(() => isLoading = true);
    try {
      final loadedLayouts = await dbHelper.getAllControllerLayouts();
      setState(() => layouts = loadedLayouts);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFF222222),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ── Layout card (saved controllers) ────────────────────────────────────
  Widget _buildLayoutCard(ControllerLayout layout) {
    final layoutAspectRatio = layout.height / layout.width;
    const previewWidth = 110.0;
    final previewHeight = previewWidth * layoutAspectRatio;

    final isFpv = layout.name.toLowerCase().contains('fpv') ||
        layout.name.toLowerCase().contains('drone');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 18,
        borderColor: Colors.white.withOpacity(0.12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ControllerPreviewPage(layoutId: layout.id),
            ),
          );
          _lockLandscape();
          _loadLayouts();
        },
        child: Row(
          children: [
            // Controller preview thumbnail
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
              ),
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: previewWidth,
                  height: previewHeight,
                  child: ControllerPreviewPage(
                    initialLayout: layout,
                    isStatic: true,
                    maxWidth: previewWidth,
                    maxHeight: previewHeight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    layout.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PillBadge(
                    label: isFpv ? 'FPV MODE 2' : 'GAMEPAD',
                    icon: isFpv ? Icons.flight : Icons.sports_esports_outlined,
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconAction(
                  icon: Icons.edit_outlined,
                  color: Colors.white,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ControllerPreviewPage(layoutId: layout.id),
                      ),
                    );
                    _lockLandscape();
                    _loadLayouts();
                  },
                ),
                const SizedBox(height: 8),
                _IconAction(
                  icon: Icons.delete_outline,
                  color: Colors.white60,
                  onTap: () => _deleteLayout(layout),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirmation ──────────────────────────────────────────────────
  Future<void> _deleteLayout(ControllerLayout layout) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        title: const Text('Eliminar Mando',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Deseas eliminar "${layout.name}"?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await dbHelper.deleteControllerLayout(layout.id);
        _loadLayouts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: const Color(0xFF222222),
            ),
          );
        }
      }
    }
  }

  // ── Add new — Frosted modal popup (under 50% width, one-hand friendly) ────
  void _showCreateLayoutMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.48,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xF2080808),
            border: Border(
              left: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Nuevo Controlador',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      Text(
                        'Selecciona un perfil optimizado',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _kTemplates.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final t = _kTemplates[i];
                            return _TemplateCard(
                              template: t,
                              onTap: () async {
                                Navigator.pop(ctx);
                                if (t.tag == 'FPV') {
                                  await _createAndOpenFpvLayout();
                                } else {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ControllerPreviewPage(),
                                    ),
                                  );
                                  _lockLandscape();
                                  _loadLayouts();
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createAndOpenFpvLayout() async {
    final screenSize = MediaQuery.of(context).size;
    final w = screenSize.width > screenSize.height
        ? screenSize.width
        : screenSize.height;
    final h = screenSize.width > screenSize.height
        ? screenSize.height
        : screenSize.width;

    final fpvLayout =
        FpvLayoutFactory.createFpvMode2Layout(screenWidth: w, screenHeight: h);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ControllerPreviewPage(initialLayout: fpvLayout),
      ),
    );
    _lockLandscape();
    _loadLayouts();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _lockLandscape();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Mis Controladores',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 24),
                onPressed: _showCreateLayoutMenu,
              ),
            ),
          ],
        ),
        body: FpvAnimatedBackground(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : layouts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flight,
                              size: 48, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay mandos guardados',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _showCreateLayoutMenu,
                            icon: const Icon(Icons.add, color: Colors.white, size: 18),
                            label: const Text(
                              'Crear Primer Mando',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: layouts.length,
                      itemBuilder: (_, i) => _buildLayoutCard(layouts[i]),
                    ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ── Template card with clean vector icon (Drone & Play icons) ───────────────
class _TemplateCard extends StatelessWidget {
  final _ControllerTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
        ),
        child: Row(
          children: [
            // Vector Icon Container (no browser images)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.8),
              ),
              child: Icon(template.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        template.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      PillBadge(label: template.tag),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    template.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 18),
          ],
        ),
      ),
    );
  }
}
