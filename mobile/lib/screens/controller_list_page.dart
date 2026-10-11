import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buana_vpad/database/db_helper.dart';
import 'package:buana_vpad/models/controller_layout.dart';
import 'package:buana_vpad/screens/controller_preview_page.dart';
import 'package:buana_vpad/screens/settings_page.dart';
import 'package:buana_vpad/utils/fpv_layout_factory.dart';
import 'package:buana_vpad/widgets/fpv_drone_3d_viewer.dart';
import 'package:buana_vpad/widgets/fpv_ui_kit.dart';

// ── Product reference images (official CDN URLs — no download, URL embed) ──
// These images are served directly from manufacturer CDNs
const _kDjiImageUrl =
    'https://www-cdn.djiits.com/dps/12d72ac8d4a954e4618728d6c94ced61.jpg';
const _kPs5ImageUrl =
    'https://gmedia.playstation.com/is/image/SIEPDC/dualsense-controller-product-thumbnail-01-en-14sep21?\$S1\$';

// ── Controller type definitions shown in the "Add" sheet ──────────────────
class _ControllerTemplate {
  final String title;
  final String subtitle;
  final String tag;
  final Color accentColor;
  final IconData fallbackIcon;
  final String? imageUrl;

  const _ControllerTemplate({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.accentColor,
    required this.fallbackIcon,
    this.imageUrl,
  });
}

const _kTemplates = [
  _ControllerTemplate(
    title: 'FPV Drone',
    subtitle: 'Mode 2 · Throttle+Yaw / Pitch+Roll',
    tag: 'FPV',
    accentColor: Color(0xFFFF6B00),
    fallbackIcon: Icons.flight,
  ),
  _ControllerTemplate(
    title: 'DJI RC 2',
    subtitle: 'DJI drone controller layout',
    tag: 'DJI',
    accentColor: Color(0xFF00D4FF),
    fallbackIcon: Icons.flight_takeoff,
    imageUrl: _kDjiImageUrl,
  ),
  _ControllerTemplate(
    title: 'PlayStation',
    subtitle: 'DualSense / DualShock layout',
    tag: 'GAME',
    accentColor: Color(0xFF7B61FF),
    fallbackIcon: Icons.gamepad,
    imageUrl: _kPs5ImageUrl,
  ),
  _ControllerTemplate(
    title: 'Generic',
    subtitle: 'Standard ABXY gamepad layout',
    tag: 'PAD',
    accentColor: Color(0xFF44BB88),
    fallbackIcon: Icons.sports_esports,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _setOrientation(context));
    _loadLayouts();
  }

  void _setOrientation(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void deactivate() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
          SnackBar(content: Text('Error loading: $e'), backgroundColor: Colors.red),
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

    final accentColor = isFpv ? const Color(0xFFFF6B00) : const Color(0xFF00D4FF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 18,
        borderColor: accentColor.withOpacity(0.15),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ControllerPreviewPage(layoutId: layout.id),
            ),
          );
          _setOrientation(context);
          _loadLayouts();
        },
        child: Row(
          children: [
            // Controller preview thumbnail
            Container(
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.2), width: 0.8),
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
                    label: isFpv ? 'FPV' : 'GAMEPAD',
                    color: accentColor,
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
                  color: const Color(0xFF00D4FF),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ControllerPreviewPage(layoutId: layout.id),
                      ),
                    );
                    _setOrientation(context);
                    _loadLayouts();
                  },
                ),
                const SizedBox(height: 8),
                _IconAction(
                  icon: Icons.delete_outline,
                  color: const Color(0xFFFF4466),
                  onTap: () => _deleteLayout(layout),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirm ──────────────────────────────────────────────────────
  Future<void> _deleteLayout(ControllerLayout layout) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Controller',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${layout.name}"?',
          style: const TextStyle(color: Color(0xFF8899AA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8899AA))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFFF4466))),
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
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ── Add new — bottom sheet with product images ──────────────────────────
  void _showCreateLayoutMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0E17),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose Controller Type',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select a layout to get started',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // Template grid
              ...List.generate(_kTemplates.length, (i) {
                final t = _kTemplates[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TemplateCard(
                    template: t,
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (t.tag == 'FPV') {
                        await _createAndOpenFpvLayout();
                      } else if (t.tag == '3D') {
                        showFpvDrone3dFullScreen(context);
                      } else {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ControllerPreviewPage()),
                        );
                        _setOrientation(context);
                        _loadLayouts();
                      }
                    },
                  ),
                );
              }),
            ],
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
    _setOrientation(context);
    _loadLayouts();
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF060A12),
        appBar: AppBar(
          backgroundColor: const Color(0xFF060A12),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Virtual Controllers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 20),
              onPressed: () async {
                await SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
                if (mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                  _setOrientation(context);
                }
              },
            ),
          ],
        ),
        body: FpvAnimatedBackground(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF00D4FF)))
              : layouts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: const Color(0xFF00D4FF),
                      onRefresh: _loadLayouts,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: layouts.length,
                        itemBuilder: (_, i) => _buildLayoutCard(layouts[i]),
                      ),
                    ),
        ),
        floatingActionButton: layouts.isNotEmpty
            ? FloatingActionButton(
                onPressed: _showCreateLayoutMenu,
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.white,
                elevation: 0,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flight, color: Color(0xFF00D4FF), size: 48),
          const SizedBox(height: 16),
          const Text('No controllers yet',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Tap + to create your first layout',
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateLayoutMenu,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Controller'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Icon action button ────────────────────────────────────────────────────
class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconAction(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25), width: 0.8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ── Template card with product image ─────────────────────────────────────
class _TemplateCard extends StatelessWidget {
  final _ControllerTemplate template;
  final VoidCallback onTap;
  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: template.accentColor.withOpacity(0.20), width: 0.8),
        ),
        child: Row(
          children: [
            // Product image or icon
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              child: SizedBox(
                width: 110,
                height: 80,
                child: template.imageUrl != null
                    ? Image.network(
                        template.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackIcon(template),
                        loadingBuilder: (_, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.white.withOpacity(0.04),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: template.accentColor,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : _fallbackIcon(template),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          template.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PillBadge(
                            label: template.tag, color: template.accentColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.subtitle,
                      style: const TextStyle(
                          color: Color(0xFF8899AA), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.chevron_right,
                  color: Color(0xFF445566), size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon(_ControllerTemplate t) {
    return Container(
      color: t.accentColor.withOpacity(0.08),
      child: Icon(t.fallbackIcon, color: t.accentColor, size: 36),
    );
  }
}
