import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class WebCameraCaptureScreen extends StatefulWidget {
  const WebCameraCaptureScreen({super.key, required this.onCaptured});

  final ValueChanged<Uint8List> onCaptured;

  @override
  State<WebCameraCaptureScreen> createState() => _WebCameraCaptureScreenState();
}

class _WebCameraCaptureScreenState extends State<WebCameraCaptureScreen> {
  static int _viewId = 0;
  late final String _viewType;
  html.VideoElement? _video;
  html.MediaStream? _stream;
  String? _error;
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    _viewType = 'ocusense-selfie-camera-${_viewId++}';
    _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      _stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': {'ideal': 'user'},
        },
        'audio': false,
      });
      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      video.srcObject = _stream;
      _video = video;
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) => video);
    } catch (_) {
      _error = 'Camera access was not available. Allow camera permission and try again.';
    }

    if (mounted) setState(() => _starting = false);
  }

  void _capture() {
    final video = _video;
    if (video == null || video.videoWidth == 0) return;

    final canvas = html.CanvasElement(width: video.videoWidth, height: video.videoHeight);
    canvas.context2D.drawImage(video, 0, 0);
    final imageData = canvas.toDataUrl('image/jpeg', 0.92).split(',').last;
    widget.onCaptured(Uint8List.fromList(base64Decode(imageData)));
  }

  @override
  void dispose() {
    for (final track in _stream?.getTracks() ?? <html.MediaStreamTrack>[]) {
      track.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Eye Photo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Position both eyes in the frame, then take a clear photo.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    color: Colors.black,
                    child: _starting
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                            : HtmlElementView(viewType: _viewType),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _starting || _error != null ? null : _capture,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Capture Photo'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
