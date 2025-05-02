// File: lib/object_detector.dart
// Mô tả: Class xử lý mô hình TFLite để nhận diện cảm xúc

import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import './utils.dart'; // Đảm bảo import utils.dart để sử dụng applyNMS

class ObjectDetector {
  Interpreter? interpreter;
  List<String>? labels;
  bool isModelLoaded = false; // Biến trạng thái để kiểm tra load mô hình
  static const int inputSize = 640; // Kích thước đầu vào của mô hình (640x640)
  static const int paddedSize = 642; // Kích thước sau khi thêm padding (642x642)
  static const double confidenceThreshold = 0.3; // Ngưỡng confidence
  static const double iouThreshold = 0.5; // Ngưỡng IoU cho NMS

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(
        'assets/best_5_float32.tflite',
        options: InterpreterOptions()
          ..threads = 4, // Sử dụng 4 luồng CPU
      );
      labels = (await rootBundle.loadString('assets/labels.txt')).split('\n');
      
      dev.log('✅ Model loaded successfully!', name: 'ObjectDetector');
      dev.log('Input tensors: ${interpreter!.getInputTensors()}', name: 'ObjectDetector');
      dev.log('Output tensors: ${interpreter!.getOutputTensors()}', name: 'ObjectDetector');
      dev.log('Labels: $labels', name: 'ObjectDetector');
      
      interpreter!.allocateTensors();
      isModelLoaded = true;
    } catch (e) {
      dev.log('❌ Failed to load model: $e', name: 'ObjectDetector', error: e);
      isModelLoaded = false;
    }
  }

  List<Map<String, dynamic>> detect(img.Image image) {
    if (interpreter == null || labels == null || !isModelLoaded) {
      dev.log('❌ Model or labels not loaded!', name: 'ObjectDetector');
      return [];
    }

    dev.log('Starting detection for image: ${image.width}x${image.height}', name: 'ObjectDetector');

    img.Image resizedImage = img.copyResize(image, width: inputSize, height: inputSize);
    dev.log('Image resized to: ${resizedImage.width}x${resizedImage.height}', name: 'ObjectDetector');

    final input = preprocessImage(resizedImage);
    final output = _runInference(input);

    final detections = _postprocessOutput(output, image.width, image.height);
    dev.log('Final detections: $detections', name: 'ObjectDetector');

    return detections;
  }

  Float32List preprocessImage(img.Image image) {
    // Tạo tensor với kích thước [1, 642, 642, 3] (sau khi thêm padding)
    final input = Float32List(1 * paddedSize * paddedSize * 3);
    int pixelIndex = 0;

    // Thêm padding 1 pixel vào mỗi bên (trên, dưới, trái, phải)
    for (int y = 0; y < paddedSize; y++) {
      for (int x = 0; x < paddedSize; x++) {
        // Nếu nằm trong vùng padding (y = 0, y = 641, x = 0, x = 641), gán giá trị 0
        if (y == 0 || y == paddedSize - 1 || x == 0 || x == paddedSize - 1) {
          input[pixelIndex++] = 0.0; // R
          input[pixelIndex++] = 0.0; // G
          input[pixelIndex++] = 0.0; // B
        } else {
          // Lấy pixel từ ảnh gốc (640x640), điều chỉnh tọa độ vì có padding
          final pixel = image.getPixel(x - 1, y - 1);
          input[pixelIndex++] = pixel.r.toDouble() / 255.0;
          input[pixelIndex++] = pixel.g.toDouble() / 255.0;
          input[pixelIndex++] = pixel.b.toDouble() / 255.0;
        }
      }
    }

    dev.log('Input tensor length: ${input.length}', name: 'ObjectDetector');
    dev.log('Input tensor sample (first 10 values): ${input.sublist(0, 10)}', name: 'ObjectDetector');

    return input;
  }

  List<List<Float32List>> _runInference(Float32List input) {
    if (interpreter == null) {
      dev.log('❌ Interpreter is null!', name: 'ObjectDetector');
      return [[]];
    }

    final inputTensor = interpreter!.getInputTensor(0);
    dev.log('Expected input shape: ${inputTensor.shape}', name: 'ObjectDetector');
    dev.log('Provided input shape: [1, $paddedSize, $paddedSize, 3]', name: 'ObjectDetector');
    dev.log('Input tensor type: ${inputTensor.type}', name: 'ObjectDetector');

    final outputTensor = interpreter!.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    dev.log('Output shape: $outputShape', name: 'ObjectDetector');
    dev.log('Output tensor type: ${outputTensor.type}', name: 'ObjectDetector');

    final numBoxes = 8400;
    final output = [
      [Float32List(12 * numBoxes)],
    ];

    try {
      interpreter!.run(input, output[0][0]);
      dev.log('Inference successful!', name: 'ObjectDetector');
      dev.log('Output tensor length: ${output[0][0].length}', name: 'ObjectDetector');
      dev.log('Output tensor sample (first 12 values): ${output[0][0].sublist(0, 12)}', name: 'ObjectDetector');
    } catch (e) {
      dev.log('❌ Inference failed: $e', name: 'ObjectDetector', error: e);
      return [[]];
    }

    return output;
  }

  List<Map<String, dynamic>> _postprocessOutput(List<List<Float32List>> output, int origWidth, int origHeight) {
    final List<Map<String, dynamic>> detections = [];
    final numClasses = labels!.length; // 8 class
    final numBoxes = 8400; // Số boxes tối đa

    if (output.isEmpty || output[0].isEmpty || output[0][0].isEmpty) {
      dev.log('❌ Output is empty!', name: 'ObjectDetector');
      return [];
    }

    dev.log('Processing output: length=${output[0][0].length}', name: 'ObjectDetector');

    for (int i = 0; i < numBoxes; i++) {
      final offset = i * 12;
      final xCenter = output[0][0][offset];
      final yCenter = output[0][0][offset + 1];
      final w = output[0][0][offset + 2];
      final h = output[0][0][offset + 3];

      // Chuẩn hóa tọa độ từ kích thước ảnh đầu vào (642x642) sang kích thước ảnh gốc
      final scaleX = origWidth / paddedSize;
      final scaleY = origHeight / paddedSize;
      final scaledXCenter = xCenter * scaleX;
      final scaledYCenter = yCenter * scaleY;
      final scaledW = w * scaleX;
      final scaledH = h * scaleY;

      final scores = List.generate(numClasses, (j) => output[0][0][offset + 4 + j]);
      final maxScore = scores.reduce((a, b) => a > b ? a : b);

      dev.log('Box $i: xCenter=$scaledXCenter, yCenter=$scaledYCenter, w=$scaledW, h=$scaledH', name: 'ObjectDetector');
      dev.log('Box $i: scores=$scores, maxScore=$maxScore', name: 'ObjectDetector');

      if (maxScore < confidenceThreshold) continue;

      final classId = scores.indexOf(maxScore);
      final emotion = labels![classId];

      detections.add({
        'box': [scaledXCenter, scaledYCenter, scaledW, scaledH],
        'emotion': emotion,
        'confidence': maxScore.toDouble(),
      });
    }

    final filteredDetections = applyNMS(detections, iouThreshold: iouThreshold);
    dev.log('Filtered detections after NMS: $filteredDetections', name: 'ObjectDetector');

    return filteredDetections.cast<Map<String, dynamic>>();
  }

  void close() {
    interpreter?.close();
    isModelLoaded = false;
  }
}