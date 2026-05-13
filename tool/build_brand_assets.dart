// One-shot tool that takes the raw brand logo and produces a
// padded variant suitable for:
//
//   * Android adaptive launcher icon foreground (33% safe zone)
//   * Android 12+ native splash (icon must fit within the central
//     768 px circle of a 1152x1152 canvas)
//
// Run with: `dart run tool/build_brand_assets.dart`. Re-run any
// time `assets/images/app_logo.png` is replaced.

import 'dart:io';

import 'package:image/image.dart' as img;

const _srcPath = 'assets/images/app_logo.png';
const _dstPath = 'assets/images/app_logo_foreground.png';

/// 1152 px canvas matches the Android 12+ splash specification.
/// 672 px of visible content ≈ 58% of the canvas, comfortably
/// inside the 768 px (≈ 66.7%) safe-zone circle, and inside the
/// 66% inner square that Android adaptive masks crop to.
const int _canvas = 1152;
const int _content = 672;

void main() async {
  final src = File(_srcPath);
  if (!await src.exists()) {
    stderr.writeln('Source logo not found at $_srcPath');
    exit(1);
  }

  final raw = img.decodeImage(await src.readAsBytes());
  if (raw == null) {
    stderr.writeln('Failed to decode $_srcPath');
    exit(1);
  }

  // Scale the logo proportionally so its longer edge equals
  // `_content`. The image package keeps alpha when resizing.
  final scaled = img.copyResize(
    raw,
    width: raw.width >= raw.height ? _content : null,
    height: raw.height > raw.width ? _content : null,
    interpolation: img.Interpolation.cubic,
  );

  final canvas = img.Image(
    width: _canvas,
    height: _canvas,
    numChannels: 4,
  );
  // Ensure the background is fully transparent.
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  final dx = (_canvas - scaled.width) ~/ 2;
  final dy = (_canvas - scaled.height) ~/ 2;
  img.compositeImage(canvas, scaled, dstX: dx, dstY: dy);

  await File(_dstPath).writeAsBytes(img.encodePng(canvas));
  stdout.writeln(
    'Wrote $_dstPath  (${_canvas}x$_canvas, content ${scaled.width}x${scaled.height})',
  );
}
