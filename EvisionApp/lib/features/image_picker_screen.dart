import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:developer' as dev;
import '../screens/bounding_box_painter.dart';
import '../object_detector.dart';
import '../utils.dart';
import 'dart:isolate';

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  final ImagePicker _picker = ImagePicker();
  final ObjectDetector _detector = ObjectDetector();
  Uint8List? imageBytes;
  List<dynamic> detectionResults = [];
  Size? imageSize;
  String status = 'Đang tải mô hình...';

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    await _detector.loadModel();
    if (mounted) {
      setState(() {
        status = _detector.interpreter != null && _detector.labels != null
            ? 'Mô hình đã tải. Chạm để chọn ảnh.'
            : 'Không thể tải mô hình hoặc nhãn.';
      });
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      status = 'Đang chọn ảnh...';
    });
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      setState(() {
        status = 'Không có ảnh nào được chọn.';
      });
      return;
    }
    await _processImage(image);
  }

  Future<void> _processImage(XFile image) async {
    setState(() {
      status = 'Đang xử lý ảnh...';
    });
    final Uint8List bytes = await image.readAsBytes();
    final img.Image? decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) {
      setState(() {
        status = 'Không thể giải mã ảnh.';
      });
      return;
    }
    imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
    setState(() {
      imageBytes = bytes;
      status = 'Ảnh đã chọn, đang chạy suy luận...';
    });
    final result = await _runInferenceInIsolate(bytes);
    if (mounted) {
      setState(() {
        detectionResults = result;
        status = result.isEmpty
            ? 'Không phát hiện cảm xúc.'
            : 'Phát hiện ${result.length} khuôn mặt với cảm xúc.';
      });
    }
  }

  Future<List<dynamic>> _runInferenceInIsolate(Uint8List imageBytes) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_inferenceIsolate, [receivePort.sendPort, imageBytes, _detector]);
    return await receivePort.first as List<dynamic>;
  }

  static void _inferenceIsolate(List<dynamic> args) async {
    final SendPort sendPort = args[0];
    final Uint8List imageBytes = args[1];
    final ObjectDetector detector = args[2];
    try {
      final input = await _preprocessImage(imageBytes);
      final List<List<List<List<double>>>> inputTensor = [];
      final List<List<List<double>>> height = [];
      for (int h = 0; h < 640; h++) {
        final List<List<double>> row = [];
        for (int w = 0; w < 640; w++) {
          final List<double> pixel = [];
          for (int c = 0; c < 3; c++) {
            pixel.add(input[(h * 640 * 3) + (w * 3) + c]);
          }
          row.add(pixel);
        }
        height.add(row);
      }
      inputTensor.add(height);
      final outputTensor = List.generate(1, (_) => List.generate(12, (_) => List.filled(8400, 0.0)));
      detector.interpreter!.run(inputTensor, outputTensor);
      List<dynamic> detections = [];
      final output = outputTensor[0];
      for (int i = 0; i < 8400; i++) {
        final List<double> box = [];
        final List<double> scores = [];
        for (int j = 0; j < 4; j++) {
          box.add(output[j][i]);
        }
        for (int j = 4; j < 12; j++) {
          scores.add(output[j][i]);
        }
        final maxScore = scores.reduce((a, b) => a > b ? a : b);
        final classIdx = scores.indexOf(maxScore);
        if (maxScore > 0.5) {
          final detection = {
            'box': box,
            'emotion': detector.labels![classIdx],
            'confidence': maxScore,
            'scores': scores,
          };
          detections.add(detection);
          dev.log(
            '✅ Detection: Box=$box, Emotion=${detector.labels![classIdx]}, Confidence=$maxScore, Scores=$scores',
            name: 'ImagePickerScreen',
          );
        }
      }
      final filteredDetections = applyNMS(detections, iouThreshold: 0.5);
      dev.log('📝 Filtered detections after NMS: $filteredDetections', name: 'ImagePickerScreen');
      sendPort.send(filteredDetections);
    } catch (e) {
      dev.log('❌ Inference error: $e', name: 'ImagePickerScreen', error: e);
      sendPort.send([]);
    }
  }

  static Future<Float32List> _preprocessImage(Uint8List imageBytes) async {
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Không thể giải mã ảnh');
    image = img.copyResize(image, width: 640, height: 640);
    final Float32List input = Float32List(1 * 640 * 640 * 3);
    int pixelIndex = 0;
    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final pixel = image.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return input;
  }

  @override
  void dispose() {
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final displayWidth = screenWidth - 32;
    final displayHeight = screenHeight * 0.5;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chọn ảnh',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/camera_capture'),
            tooltip: 'Chụp ảnh',
          ),
          IconButton(
            icon: const Icon(Icons.video_library, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/video_picker'),
            tooltip: 'Chọn video',
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/realtime_detection'),
            tooltip: 'Phát hiện thời gian thực',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber, width: 4),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.white,
                    height: displayHeight,
                    width: displayWidth,
                    child: _buildMainContent(displayWidth, displayHeight),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildButtons(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        status.contains('Lỗi')
                            ? Icons.error
                            : status.contains('chọn') || status.contains('phát hiện')
                                ? Icons.check_circle
                                : Icons.hourglass_empty,
                        color: status.contains('Lỗi') ? Colors.red : Colors.green,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (imageBytes != null && detectionResults.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kết quả phát hiện',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...detectionResults.map((result) {
                          final String displayEmotion = result['emotion'].split('_').last;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  _getEmotionIcon(displayEmotion),
                                  color: _getEmotionColor(displayEmotion),
                                  size: 30,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cảm xúc: $displayEmotion',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Độ tin cậy: ${(result['confidence'] * 100).toStringAsFixed(2)}%',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(double displayWidth, double displayHeight) {
    if (imageBytes == null) {
      return const Center(
        child: Text(
          'Chưa có ảnh nào được chọn',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    } else {
      return imageBytes != null && imageSize != null
          ? LayoutBuilder(
              builder: (context, constraints) {
                final imageAspectRatio = imageSize!.width / imageSize!.height;
                final displayAspectRatio = displayWidth / displayHeight;
                double scaleX, scaleY, offsetX = 0, offsetY = 0;

                if (imageAspectRatio > displayAspectRatio) {
                  // Ảnh rộng hơn display, scale theo chiều rộng
                  scaleX = displayWidth / imageSize!.width;
                  scaleY = scaleX;
                  offsetX = 0;
                  offsetY = (displayHeight - imageSize!.height * scaleY) / 2;
                } else {
                  // Ảnh cao hơn display, scale theo chiều cao
                  scaleY = displayHeight / imageSize!.height;
                  scaleX = scaleY;
                  offsetX = (displayWidth - imageSize!.width * scaleX) / 2;
                  offsetY = 0;
                }

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(
                        imageBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (detectionResults.isNotEmpty)
                      CustomPaint(
                        painter: BoundingBoxPainter(
                          detections: detectionResults,
                          imageSize: imageSize!,
                          displaySize: Size(displayWidth, displayHeight),
                          scaleX: scaleX,
                          scaleY: scaleY,
                          offsetX: offsetX,
                          offsetY: offsetY,
                        ),
                        child: SizedBox(
                          width: displayWidth,
                          height: displayHeight,
                        ),
                      ),
                  ],
                );
              },
            )
          : const Center(child: Text('Không có ảnh nào được chọn', style: TextStyle(fontSize: 16, color: Colors.grey)));
    }
  }

  Widget _buildButtons() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Chọn ảnh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry':
        return Icons.mood_bad;
      case 'disgust':
        return Icons.sick;
      case 'fear':
        return Icons.warning;
      case 'happy':
        return Icons.mood;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'surprise':
        return Icons.sentiment_neutral;
      case 'neutral':
        return Icons.sentiment_satisfied;
      case 'surprised':
        return Icons.mood;
      case 'contempt':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.face;
    }
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry':
        return Colors.red;
      case 'disgust':
        return Colors.green;
      case 'fear':
        return Colors.purple;
      case 'happy':
        return Colors.yellow;
      case 'sad':
        return Colors.blue;
      case 'surprise':
        return Colors.orange;
      case 'neutral':
        return Colors.grey;
      case 'surprised':
        return Colors.pink;
      case 'contempt':
        return Colors.deepOrange;
      default:
        return Colors.black;
    }
  }
}