import 'dart:typed_data';

import 'package:flutter/material.dart';

class WebCameraCaptureScreen extends StatelessWidget {
  const WebCameraCaptureScreen({super.key, required this.onCaptured});

  final ValueChanged<Uint8List> onCaptured;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
