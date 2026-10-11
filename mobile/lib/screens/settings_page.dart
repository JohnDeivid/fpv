import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buana_vpad/database/db_helper.dart';
import 'package:buana_vpad/enums/link.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buana_vpad/utils/settings_manager.dart';
import 'package:buana_vpad/widgets/fpv_ui_kit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _deviceName;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final name = await SettingsManager.getDeviceName();
    final id = await SettingsManager.getDeviceId();
    setState(() {
      _deviceName = name;
      _deviceId = id;
    });
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        title: const Text('Eliminar todos los mandos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro de que deseas eliminar todas las configuraciones de controles? Esta acción no se puede deshacer.',
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
            child: const Text('Eliminar Todo',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dbHelper = DatabaseHelper();
        await dbHelper.deleteAllControllerLayouts();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Mandos eliminados correctamente'),
              backgroundColor: const Color(0xFF222222),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: const Color(0xFF222222),
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditDeviceNameDialog(
      BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        title: const Text('Editar Nombre del Dispositivo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ingresa un nombre',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await SettingsManager.setDeviceName(newName);
      setState(() {
        _deviceName = newName;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nombre actualizado'),
            backgroundColor: Color(0xFF222222),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text(
          'Configuraciones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FpvAnimatedBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          children: [
            // Device Section
            _buildSection(
              title: 'DISPOSITIVO',
              children: [
                _buildListTile(
                  title: 'Device ID',
                  subtitle: _deviceId ?? 'Cargando...',
                  trailing: const Icon(
                    Icons.copy,
                    color: Colors.white70,
                    size: 18,
                  ),
                  onTap: () async {
                    if (_deviceId != null) {
                      await Clipboard.setData(ClipboardData(text: _deviceId!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device ID copiado al portapapeles'),
                            backgroundColor: Color(0xFF222222),
                          ),
                        );
                      }
                    }
                  },
                ),
                _buildListTile(
                  title: 'Nombre de Dispositivo',
                  subtitle: _deviceName ?? 'Cargando...',
                  trailing: const Icon(
                    Icons.edit,
                    color: Colors.white70,
                    size: 18,
                  ),
                  onTap: () =>
                      _showEditDeviceNameDialog(context, _deviceName ?? ''),
                ),
              ],
            ),

            // Application Section
            _buildSection(
              title: 'APLICACIÓN',
              children: [
                _buildListTile(
                  title: 'Eliminar Todos los Mandos',
                  subtitle: 'Restablecer esquemas de control guardados',
                  trailing: const Icon(
                    Icons.delete_forever,
                    color: Colors.white54,
                    size: 18,
                  ),
                  onTap: () => _showDeleteConfirmation(context),
                ),
              ],
            ),

            // Developer Section
            _buildSection(
              title: 'DESARROLLADOR',
              children: [
                _buildListTile(
                  title: 'Perfil GitHub',
                  subtitle: 'Código y proyectos',
                  trailing: const Icon(
                    Icons.launch,
                    color: Colors.white70,
                    size: 18,
                  ),
                  onTap: () => _launchUrl(Link.developerGithubAccount.path),
                ),
              ],
            ),

            // Project Section
            _buildSection(
              title: 'PROYECTO & VERSIÓN',
              children: [
                _buildListTile(
                  title: 'Repositorio Buana VPad',
                  subtitle: 'Ver código fuente',
                  trailing: const Icon(
                    Icons.launch,
                    color: Colors.white70,
                    size: 18,
                  ),
                  onTap: () => _launchUrl(Link.githubSourceRepo.path),
                ),
                _buildListTile(
                  title: 'Versión del Sistema',
                  subtitle: 'v2.5.0 • Monochrome FPV Pro Edition',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 16,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
