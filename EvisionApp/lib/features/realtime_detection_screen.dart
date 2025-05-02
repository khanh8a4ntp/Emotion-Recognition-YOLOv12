import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:developer' as dev;
import '../screens/bounding_box_painter.dart';
import '../object_detector.dart';
import '../utils.dart';
import 'dart:isolate';

// Định nghĩa enum ở cấp độ cao nhất
enum CameraMode { off, streaming }

class RealtimeDetectionScreen extends StatefulWidget {
  const RealtimeDetectionScreen({super.key});

  @override
  State<RealtimeDetectionScreen> createState() => _RealtimeDetectionScreenState();
}

class _RealtimeDetectionScreenState extends State<RealtimeDetectionScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  final ObjectDetector _detector = ObjectDetector();
  List<dynamic> detectionResults = [];
  Size? imageSize;
  Uint8List? thumbnailBytes;
  String status = 'Đang tải mô hình...';
  bool _isProcessing = false;
  int _selectedCameraIndex = 0; // 0 cho camera sau, 1 cho camera trước
  CameraMode _cameraMode = CameraMode.off;

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
            ? 'Mô hình đã tải. Chạm để bật camera.'
            : 'Không thể tải mô hình hoặc nhãn.';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras!.isNotEmpty) {
        _selectedCameraIndex = 0; // Mặc định là camera sau
        _controller = CameraController(
          cameras![_selectedCameraIndex],
          ResolutionPreset.medium,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {});
        }
      } else {
        setState(() {
          status = 'Không có camera khả dụng.';
        });
      }
    } catch (e) {
      dev.log('❌ Lỗi khởi tạo camera: $e', name: 'RealtimeDetectionScreen', error: e);
      setState(() {
        status = 'Lỗi khởi tạo camera: $e';
      });
    }
  }

  Future<void> _startCamera() async {
    if (_cameraMode == CameraMode.streaming) {
      // Nếu camera đã bật, dừng luồng và quay lại trạng thái ban đầu
      await _controller?.stopImageStream();
      await _controller?.dispose();
      _controller = null;
      setState(() {
        _cameraMode = CameraMode.off;
        status = 'Mô hình đã tải. Chạm để bật camera.';
        detectionResults = [];
      });
      return;
    }

    setState(() {
      status = 'Đang khởi tạo camera...';
    });
    await _initializeCamera();
    if (_controller != null && _controller!.value.isInitialized) {
      // Bắt đầu luồng video và nhận diện thời gian thực
      await _controller!.startImageStream(_processCameraImage);
      setState(() {
        _cameraMode = CameraMode.streaming;
        status = 'Camera đã sẵn sàng';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.length < 2) return;
    setState(() {
      status = 'Đang chuyển camera...';
    });

    // Dừng luồng hiện tại và giải phóng tài nguyên
    if (_controller != null) {
      await _controller!.stopImageStream();
      await _controller!.dispose();
    }

    // Chuyển đổi camera
    _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras!.length;
    _controller = CameraController(
      cameras![_selectedCameraIndex],
      ResolutionPreset.medium,
    );

    // Khởi tạo và bắt đầu luồng mới
    await _controller!.initialize();
    await _controller!.startImageStream(_processCameraImage);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        status = 'Camera đã sẵn sàng';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    try {
      // Chuyển đổi CameraImage thành Uint8List
      final Uint8List bytes = _convertCameraImageToBytes(image);
      final img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        setState(() {
          _isProcessing = false;
          status = 'Không thể giải mã khung hình.';
        });
        return;
      }

      imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      thumbnailBytes = bytes;

      // Chạy suy luận trên khung hình
      final result = await _runInferenceInIsolate(bytes);
      if (mounted) {
        setState(() {
          detectionResults = result;
          status = result.isEmpty
              ? 'Không phát hiện cảm xúc.'
              : 'Phát hiện ${result.length} khuôn mặt với cảm xúc.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      dev.log('❌ Lỗi xử lý khung hình: $e', name: 'RealtimeDetectionScreen', error: e);
      setState(() {
        _isProcessing = false;
        status = 'Lỗi xử lý khung hình: $e';
      });
    }
  }

  Uint8List _convertCameraImageToBytes(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image convertedImage = img.Image(width: width, height: height);

    // Chuyển đổi YUV420 sang RGB
    final Uint8List yBuffer = image.planes[0].bytes;
    final Uint8List uBuffer = image.planes[1].bytes;
    final Uint8List vBuffer = image.planes[2].bytes;

    const int ySize = 1;
    const int uvSize = 2;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = (x ~/ uvSize) + (y ~/ uvSize) * (width ~/ uvSize);
        final int yIndex = y * width + x;

        final int yp = yBuffer[yIndex];
        final int up = uBuffer[uvIndex];
        final int vp = vBuffer[uvIndex];

        // Chuyển đổi YUV sang RGB
        final int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        final int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        final int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        convertedImage.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }

    return Uint8List.fromList(img.encodePng(convertedImage));
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
            name: 'RealtimeDetectionScreen',
          );
        }
      }
      final filteredDetections = applyNMS(detections, iouThreshold: 0.5);
      dev.log('📝 Filtered detections after NMS: $filteredDetections', name: 'RealtimeDetectionScreen');
      sendPort.send(filteredDetections);
    } catch (e) {
      dev.log('❌ Inference error: $e', name: 'RealtimeDetectionScreen', error: e);
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
    _controller?.stopImageStream();
    _controller?.dispose();
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
          'Phát hiện thời gian thực',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/image_picker'),
            tooltip: 'Chọn ảnh',
          ),
          IconButton(
            icon: const Icon(Icons.video_library, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/video_picker'),
            tooltip: 'Chọn video',
          ),
          IconButton(
            icon: const Icon(Icons.camera, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/camera_capture'),
            tooltip: 'Chụp ảnh bằng Camera',
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
                            : status.contains('sẵn sàng') || status.contains('phát hiện')
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
            if (_cameraMode == CameraMode.streaming && detectionResults.isNotEmpty)
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
    if (_cameraMode == CameraMode.off) {
      return const Center(
        child: Text(
          'Bật camera để nhận diện',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    } else {
      return _controller != null && _controller!.value.isInitialized
          ? LayoutBuilder(
              builder: (context, constraints) {
                final cameraAspectRatio = _controller!.value.aspectRatio;
                final displayAspectRatio = displayWidth / displayHeight;
                double scaleX, scaleY;
                double offsetX = 0, offsetY = 0;

                if (cameraAspectRatio > displayAspectRatio) {
                  // Ảnh rộng hơn display
                  scaleX = displayWidth / imageSize!.width;
                  scaleY = scaleX;
                  offsetY = (displayHeight - imageSize!.height * scaleY) / 2;
                } else {
                  // Ảnh cao hơn display
                  scaleY = displayHeight / imageSize!.height;
                  scaleX = scaleY;
                  offsetX = (displayWidth - imageSize!.width * scaleX) / 2;
                }

                return Stack(
                  children: [
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: _controller!.value.previewSize!.height,
                          height: _controller!.value.previewSize!.width,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    ),
                    if (detectionResults.isNotEmpty && imageSize != null)
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
          : const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildButtons() {
    if (_cameraMode == CameraMode.off) {
      return Center(
        child: GestureDetector(
          onTap: _startCamera,
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
                Icon(Icons.camera_alt, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Bật Camera',
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
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _startCamera,
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
                      Icon(Icons.camera, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tắt Camera',
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
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _switchCamera,
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
                      Icon(Icons.flip_camera_ios, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Flip',
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
            ),
          ),
        ],
      );
    }
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