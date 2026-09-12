import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class TravelerMapMarker {
  const TravelerMapMarker._();

  static Future<BitmapDescriptor> build() async {
    final bytes = await _drawCurrentCarMarker();
    return BitmapDescriptor.bytes(bytes, width: 66, height: 66);
  }

  static Future<Uint8List> _drawCurrentCarMarker() async {
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

    final carBody = RRect.fromRectAndRadius(
      const Rect.fromLTWH(51, 84, 90, 36),
      const Radius.circular(16),
    );
    canvas.drawRRect(carBody, paint..color = Colors.white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, 64, 52, 34),
        const Radius.circular(13),
      ),
      paint..color = Colors.white,
    );

    final windshield = Path()
      ..moveTo(78, 69)
      ..lineTo(114, 69)
      ..lineTo(124, 94)
      ..lineTo(68, 94)
      ..close();
    canvas.drawPath(
      windshield,
      paint..color = AppColors.primary.withValues(alpha: 0.24),
    );
    canvas.drawLine(
      const Offset(96, 68),
      const Offset(96, 94),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(57, 94, 12, 10),
        const Radius.circular(5),
      ),
      paint..color = AppColors.accent,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(123, 94, 12, 10),
        const Radius.circular(5),
      ),
      paint..color = AppColors.accent,
    );
    canvas.drawCircle(const Offset(72, 123), 12, paint..color = Colors.black87);
    canvas.drawCircle(
        const Offset(120, 123), 12, paint..color = Colors.black87);
    canvas.drawCircle(const Offset(72, 123), 5, paint..color = Colors.white);
    canvas.drawCircle(const Offset(120, 123), 5, paint..color = Colors.white);

    final image = await recorder.endRecording().toImage(
          width.toInt(),
          height.toInt(),
        );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
