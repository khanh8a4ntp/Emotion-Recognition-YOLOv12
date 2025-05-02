import 'package:flutter/material.dart';
import 'dart:developer' as dev;

class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> detections;
  final Size imageSize;
  final Size displaySize;
  final double scaleX;
  final double scaleY;
  final double offsetX;
  final double offsetY;
  final Color boxColor;
  final Color textColor;

  BoundingBoxPainter({
    required this.detections,
    required this.imageSize,
    required this.displaySize,
    required this.scaleX,
    required this.scaleY,
    required this.offsetX,
    required this.offsetY,
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
      final double scaleXImage = imageSize.width / 640;
      final double scaleYImage = imageSize.height / 640;
      final double scaledX = modelX * scaleXImage;
      final double scaledY = modelY * scaleYImage;
      final double scaledW = modelW * scaleXImage;
      final double scaledH = modelH * scaleYImage;

      // Chuyển đổi tọa độ từ không gian ảnh gốc sang không gian hiển thị
      final double displayX = scaledX * scaleX + offsetX;
      final double displayY = scaledY * scaleY + offsetY;
      final double displayW = scaledW * scaleX;
      final double displayH = scaledH * scaleY;

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