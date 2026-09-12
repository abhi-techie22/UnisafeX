import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class TravelerMapMarker {
  const TravelerMapMarker._();

  static Future<BitmapDescriptor> build() async {
    final bytes = await _drawTravelerMarker();
    return BitmapDescriptor.bytes(bytes, width: 66, height: 66);
  }

  static Future<Uint8List> _drawTravelerMarker() async {
    const width = 192.0;
    const height = 192.0;
    const center = Offset(width / 2, height / 2);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    canvas.drawCircle(
      center.translate(0, 7),
      78,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(center, 80, paint..color = Colors.white);
    canvas.drawCircle(center, 68, paint..color = AppColors.primary);
    canvas.drawCircle(
      center,
      54,
      paint..color = AppColors.primary.withValues(alpha: 0.88),
    );

    final whitePaint = Paint()
      ..isAntiAlias = true
      ..color = Colors.white;
    final accentPaint = Paint()
      ..isAntiAlias = true
      ..color = AppColors.accent;
    final darkPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF173F35);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(122, 82, 28, 52),
        const Radius.circular(14),
      ),
      darkPaint,
    );
    canvas.drawCircle(const Offset(136, 96), 5, whitePaint);
    canvas.drawCircle(const Offset(136, 120), 5, whitePaint);

    canvas.drawLine(
      const Offset(78, 118),
      const Offset(61, 148),
      Paint()
        ..isAntiAlias = true
        ..color = Colors.white
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(110, 118),
      const Offset(129, 148),
      Paint()
        ..isAntiAlias = true
        ..color = Colors.white
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    final torso = Path()
      ..moveTo(74, 133)
      ..quadraticBezierTo(96, 111, 118, 133)
      ..lineTo(126, 161)
      ..lineTo(66, 161)
      ..close();
    canvas.drawPath(torso, whitePaint);
    canvas.drawPath(
      Path()
        ..moveTo(84, 130)
        ..quadraticBezierTo(96, 141, 108, 130)
        ..lineTo(103, 160)
        ..lineTo(89, 160)
        ..close(),
      accentPaint,
    );

    canvas.drawCircle(const Offset(96, 84), 24, whitePaint);
    canvas.drawCircle(
        const Offset(96, 86), 16, paint..color = AppColors.primary);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(66, 58, 60, 17),
        const Radius.circular(8),
      ),
      whitePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 48, 40, 18),
        const Radius.circular(9),
      ),
      whitePaint,
    );
    canvas.drawLine(
      const Offset(77, 113),
      const Offset(115, 153),
      Paint()
        ..isAntiAlias = true
        ..color = AppColors.primary.withValues(alpha: 0.45)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    final image = await recorder.endRecording().toImage(
          width.toInt(),
          height.toInt(),
        );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
