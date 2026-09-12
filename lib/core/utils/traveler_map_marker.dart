import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class TravelerMapMarker {
  const TravelerMapMarker._();

  static Future<BitmapDescriptor> build() async {
    final bytes = await _drawTravelerMarker();
    return BitmapDescriptor.bytes(bytes, width: 64, height: 78);
  }

  static Future<Uint8List> _drawTravelerMarker() async {
    const width = 192.0;
    const height = 234.0;
    const center = Offset(width / 2, 86);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    canvas.drawCircle(
      center.translate(0, 10),
      78,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(center, 78, paint..color = Colors.white);
    canvas.drawCircle(center, 68, paint..color = AppColors.primary);

    final pointer = Path()
      ..moveTo(width / 2 - 22, 144)
      ..quadraticBezierTo(width / 2, height - 10, width / 2 + 22, 144)
      ..close();
    canvas.drawPath(pointer, paint..color = AppColors.primary);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(66, 78, 60, 50),
        const Radius.circular(18),
      ),
      paint..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(56, 90, 28, 38),
        const Radius.circular(12),
      ),
      paint..color = AppColors.accent,
    );
    canvas.drawCircle(const Offset(96, 62), 22, paint..color = Colors.white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 42, 40, 14),
        const Radius.circular(8),
      ),
      paint..color = AppColors.accent,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(68, 52, 56, 8),
        const Radius.circular(5),
      ),
      paint..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(111, 92, 22, 32),
        const Radius.circular(8),
      ),
      paint..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
        const Offset(124, 91), 5, paint..color = AppColors.accent);

    final image = await recorder.endRecording().toImage(
          width.toInt(),
          height.toInt(),
        );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
