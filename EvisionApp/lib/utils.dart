import 'dart:math';

List<dynamic> applyNMS(List<dynamic> detections, {double iouThreshold = 0.5}) { // Giảm iouThreshold từ 0.2 xuống 0.1
  if (detections.isEmpty) return [];

  // Sắp xếp detections theo confidence (giảm dần)
  detections.sort((a, b) => b['confidence'].compareTo(a['confidence']));

  List<dynamic> filteredDetections = [];
  List<bool> keep = List.filled(detections.length, true);

  for (int i = 0; i < detections.length; i++) {
    if (!keep[i]) continue;

    filteredDetections.add(detections[i]);
    final box1 = detections[i]['box'];

    for (int j = i + 1; j < detections.length; j++) {
      if (!keep[j]) continue;

      final box2 = detections[j]['box'];
      final iou = _calculateIoU(box1, box2);

      if (iou > iouThreshold) {
        keep[j] = false;
      }
    }
  }

  return filteredDetections;
}

double _calculateIoU(List<double> box1, List<double> box2) {
  // box: [xCenter, yCenter, w, h]
  final x1Min = box1[0] - box1[2] / 2;
  final y1Min = box1[1] - box1[3] / 2;
  final x1Max = box1[0] + box1[2] / 2;
  final y1Max = box1[1] + box1[3] / 2;

  final x2Min = box2[0] - box2[2] / 2;
  final y2Min = box2[1] - box2[3] / 2;
  final x2Max = box2[0] + box2[2] / 2;
  final y2Max = box2[1] + box2[3] / 2;

  // Tính tọa độ giao nhau
  final xMin = max(x1Min, x2Min);
  final yMin = max(y1Min, y2Min);
  final xMax = min(x1Max, x2Max);
  final yMax = min(y1Max, y2Max);

  final intersection = max(0.0, xMax - xMin) * max(0.0, yMax - yMin);
  final area1 = box1[2] * box1[3];
  final area2 = box2[2] * box2[3];
  final union = area1 + area2 - intersection;

  return intersection / union;
}