import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Pure ambient 3D Background Viewer for the FPV Drone & Radio
/// Serves strictly as a background scene: no VR, no AR, no fullscreen buttons, transparent canvas.
class FpvDrone3dViewer extends StatefulWidget {
  final double? height;
  final bool isFullScreen;

  const FpvDrone3dViewer({
    super.key,
    this.height,
    this.isFullScreen = true,
  });

  @override
  State<FpvDrone3dViewer> createState() => _FpvDrone3dViewerState();
}

class _FpvDrone3dViewerState extends State<FpvDrone3dViewer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;
  bool _hasError = false;

  // Parameters stripped of VR, AR, fullscreen, inspector, annotations, and watermark.
  static const String _sketchfabUrl =
      'https://sketchfab.com/models/6544a01c9b4042e8b12eb7f1a9f22b2d/embed?'
      'autostart=1&internal=1&ui_theme=dark&ui_infos=0&ui_watermark=0&'
      'ui_help=0&ui_settings=0&ui_inspector=0&ui_annotations=0&ui_stop=0&'
      'ui_vr=0&ui_ar=0&ui_fullscreen=0&ui_animations=0&transparent=1&dnt=1';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
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
            debugPrint('3D Background WebResourceError: ${error.description}');
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
      color: Colors.transparent,
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
            const SizedBox.shrink(),

          // 2. Minimalist subtle loading indicator (fades away completely)
          if (_isLoading)
            Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress / 100 : null,
                  strokeWidth: 1.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white38),
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
