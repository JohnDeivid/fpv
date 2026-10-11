import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Interactive 3D Viewer Widget for the FPV Freestyle Drone & RadioMaster Transmitter
class FpvDrone3dViewer extends StatefulWidget {
  final double height;
  final bool isFullScreen;
  final VoidCallback? onToggleFullScreen;

  const FpvDrone3dViewer({
    super.key,
    this.height = 320,
    this.isFullScreen = false,
    this.onToggleFullScreen,
  });

  @override
  State<FpvDrone3dViewer> createState() => _FpvDrone3dViewerState();
}

class _FpvDrone3dViewerState extends State<FpvDrone3dViewer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;
  bool _hasError = false;

  static const String _sketchfabUrl =
      'https://sketchfab.com/models/6544a01c9b4042e8b12eb7f1a9f22b2d/embed?'
      'autostart=1&internal=1&ui_theme=dark&ui_infos=0&ui_watermark=0&'
      'ui_help=0&ui_settings=0&ui_inspector=0&ui_annotations=0&ui_stop=0&'
      'transparent=0&dnt=1';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF121418))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
                if (progress == 100) {
                  _isLoading = false;
                }
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Sketchfab 3D WebResourceError: ${error.description}');
            if (mounted && _loadingProgress < 20) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_sketchfabUrl));
  }

  @override
  Widget build(BuildContext context) {
    final container = Container(
      height: widget.isFullScreen ? null : widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF14171E),
        borderRadius: BorderRadius.circular(widget.isFullScreen ? 0 : 16),
        border: Border.all(
          color: Colors.orange.withOpacity(widget.isFullScreen ? 0 : 0.45),
          width: 1.5,
        ),
        boxShadow: widget.isFullScreen
            ? []
            : [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. The Interactive 3D WebGL Canvas
          if (!_hasError)
            WebViewWidget(
              controller: _controller,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            )
          else
            _buildErrorState(),

          // 2. Futuristic Loading Overlay
          if (_isLoading) _buildLoadingState(),

          // 3. Top Badges & FullScreen Action Header
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.view_in_ar, size: 14, color: Colors.orange),
                      SizedBox(width: 5),
                      Text(
                        '3D FPV MODEL • PBR 4K',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (widget.onToggleFullScreen != null)
                  InkWell(
                    onTap: widget.onToggleFullScreen,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        widget.isFullScreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 4. Bottom Interactive Gesture Tip
          Positioned(
            bottom: 8,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 13, color: Colors.white70),
                  SizedBox(width: 6),
                  Text(
                    'Gira con 1 dedo • Zoom / Panorámica con 2 dedos',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return container;
  }

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xFF14171E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: CircularProgressIndicator(
                    value: _loadingProgress > 0 ? _loadingProgress / 100 : null,
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    backgroundColor: Colors.white12,
                  ),
                ),
                const Icon(Icons.flight_takeoff,
                    color: Colors.orange, size: 24),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Cargando Modelo 3D ($_loadingProgress%)...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Flywoo Explorer LR 4" + RadioMaster TX12',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 36),
            const SizedBox(height: 10),
            const Text(
              'No se pudo cargar el modelo 3D online',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _controller.reload();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// Helper dialog to view the 3D model in full screen
void showFpvDrone3dFullScreen(BuildContext context) {
  showDialog(
    context: context,
    useSafeArea: false,
    builder: (ctx) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'FPV Kit 3D (Drone & Radio)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
      body: const SafeArea(
        child: FpvDrone3dViewer(
          isFullScreen: true,
        ),
      ),
    ),
  );
}
