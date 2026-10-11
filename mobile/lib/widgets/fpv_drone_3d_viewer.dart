import 'package:flutter/foundation.dart';
import 'package:flutter/gestures';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Interactive 3D Viewer Widget for the FPV Drone & RadioMaster Transmitter
/// Pure monochrome aesthetic: dark slate, crisp whites, frosted glass. ZERO BLUE / ORANGE.
class FpvDrone3dViewer extends StatefulWidget {
  final double? height;
  final bool isFullScreen;
  final bool showHeader;
  final VoidCallback? onToggleFullScreen;

  const FpvDrone3dViewer({
    super.key,
    this.height,
    this.isFullScreen = false,
    this.showHeader = true,
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
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
                if (progress >= 95) {
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
    return Container(
      height: widget.isFullScreen ? null : widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(widget.isFullScreen ? 0 : 20),
        border: Border.all(
          color: Colors.white.withOpacity(widget.isFullScreen ? 0 : 0.08),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
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

          // 2. Loading Overlay
          if (_isLoading) _buildLoadingState(),

          // 3. Top Badges & FullScreen Action Header (optional)
          if (widget.showHeader)
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.view_in_ar, size: 13, color: Colors.white.withOpacity(0.85)),
                        const SizedBox(width: 5),
                        Text(
                          '3D FPV MODEL • PBR 4K',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
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
                          widget.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xFF080808),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: _loadingProgress > 0 ? _loadingProgress / 100 : null,
                    strokeWidth: 2.0,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    backgroundColor: Colors.white12,
                  ),
                ),
                const Icon(Icons.flight, color: Colors.white70, size: 22),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Cargando Modelo 3D ($_loadingProgress%)...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Flywoo Explorer LR 4" • RadioMaster TX12',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
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
            const Icon(Icons.wifi_off, color: Colors.white54, size: 32),
            const SizedBox(height: 10),
            const Text(
              'Visor 3D offline / sin conexión',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _controller.reload();
              },
              icon: const Icon(Icons.refresh, size: 15, color: Colors.white),
              label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
      body: const SafeArea(
        child: FpvDrone3dViewer(
          isFullScreen: true,
          showHeader: false,
        ),
      ),
    ),
  );
}
