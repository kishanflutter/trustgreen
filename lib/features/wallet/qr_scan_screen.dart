import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/tokens.dart';

/// One-shot QR scan helper. Pushes itself and pops with the scanned
/// string (or `null` if the user cancels). Strips `ethereum:` or
/// `chain:`-style URI prefixes so the caller gets a bare address.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  static Future<String?> open(BuildContext context) {
    return Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
  }

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;
      final cleaned = _cleanAddress(raw);
      _handled = true;
      Navigator.of(context).pop(cleaned);
      return;
    }
  }

  /// Strips common URI prefixes (`ethereum:0x…`, `bitcoin:bc1…`)
  /// and trims any `?amount=…` payload off the back.
  String _cleanAddress(String raw) {
    var s = raw.trim();
    final colonIdx = s.indexOf(':');
    if (colonIdx > 0 && colonIdx < 12) {
      s = s.substring(colonIdx + 1);
    }
    final qIdx = s.indexOf('?');
    if (qIdx > 0) {
      s = s.substring(0, qIdx);
    }
    return s.trim();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scan QR'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
          IconButton(
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Reticle overlay
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: AppRadius.brMd,
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: AppRadius.brMd,
                ),
                child: const Text(
                  'Align QR within the frame',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
