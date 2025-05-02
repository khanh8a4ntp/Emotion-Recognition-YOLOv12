// File: lib/screens/bounding_box_painter.dart
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> detections;
  final Size imageSize;
  final Size displaySize;
  final Color boxColor;
  final Color textColor;

  BoundingBoxPainter({
    required this.detections,
    required this.imageSize,
    required this.displaySize,
    this.boxColor = Colors.yellow,
    this.textColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var detection in detections) {
      final List<double> box = detection['box'];
      final String emotion = detection['emotion'];
      final double confidence = detection['confidence'];

      // Chuyển đổi tên cảm xúc (bỏ số và dấu gạch dưới)
      final String displayEmotion = emotion.split('_').last;

      // Giả định tọa độ là center-based và chuẩn hóa [0,1]
      final double xCenter = box[0];
      final double yCenter = box[1];
      final double w = box[2];
      final double h = box[3];

      // Chuyển từ chuẩn hóa [0,1] sang không gian mô hình 640x640
      final double modelXCenter = xCenter * 640;
      final double modelYCenter = yCenter * 640;
      final double modelW = w * 640;
      final double modelH = h * 640;

      // Chuyển từ center-based sang top-left
      final double modelX = modelXCenter - modelW / 2;
      final double modelY = modelYCenter - modelH / 2;

      // Chuyển đổi tọa độ từ không gian mô hình (640x640) sang không gian ảnh gốc
      final double scaleX = imageSize.width / 640;
      final double scaleY = imageSize.height / 640;
      final double scaledX = modelX * scaleX;
      final double scaledY = modelY * scaleY;
      final double scaledW = modelW * scaleX;
      final double scaledH = modelH * scaleY;

      // Tính tỷ lệ hiển thị với BoxFit.contain
      final double imageAspectRatio = imageSize.width / imageSize.height;
      final double displayAspectRatio = displaySize.width / displaySize.height;
      double displayScaleX, displayScaleY, offsetX, offsetY;

      if (imageAspectRatio > displayAspectRatio) {
        // Ảnh rộng hơn display, scale theo chiều rộng
        displayScaleX = displaySize.width / imageSize.width;
        displayScaleY = displayScaleX;
        offsetX = 0;
        offsetY = (displaySize.height - imageSize.height * displayScaleY) / 2;
      } else {
        // Ảnh cao hơn display, scale theo chiều cao
        displayScaleY = displaySize.height / imageSize.height;
        displayScaleX = displayScaleY;
        offsetX = (displaySize.width - imageSize.width * displayScaleX) / 2;
        offsetY = 0;
      }

      // Chuyển đổi tọa độ từ không gian ảnh gốc sang không gian hiển thị
      final double displayX = scaledX * displayScaleX + offsetX;
      final double displayY = scaledY * displayScaleY + offsetY;
      final double displayW = scaledW * displayScaleX;
      final double displayH = scaledH * displayScaleY;

      // Debug tọa độ
      dev.log(
        '🖼️ Bounding box: x=$displayX, y=$displayY, w=$displayW, h=$displayH',
        name: 'BoundingBoxPainter',
      );

      // Vẽ bounding box
      canvas.drawRect(
        Rect.fromLTWH(displayX, displayY, displayW, displayH),
        paint,
      );

      // Vẽ nhãn (emotion và confidence)
      final textSpan = TextSpan(
        text: '$displayEmotion (${(confidence * 100).toStringAsFixed(1)}%)',
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: boxColor.withOpacity(0.7),
        ),
      );
      textPainter.text = textSpan;
      textPainter.layout();
      textPainter.paint(canvas, Offset(displayX, displayY - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}