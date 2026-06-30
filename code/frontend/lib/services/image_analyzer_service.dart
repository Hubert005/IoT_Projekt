import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ImageProfile {
  final bool faceDetected;
  final double? estimatedSmile;
  final double? estimatedLeftEyeOpen;
  final double? estimatedRightEyeOpen;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;
  final List<String> labels;

  ImageProfile({
    required this.faceDetected,
    this.estimatedSmile,
    this.estimatedLeftEyeOpen,
    this.estimatedRightEyeOpen,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.labels = const [],
  });

  bool get isSmiling => estimatedSmile != null && estimatedSmile! > 0.4;

  bool get isNeutralOrSad => !isSmiling;

  String get emotion {
    if (estimatedSmile == null) return 'unknown';
    if (estimatedSmile! > 0.6) return 'happy';
    if (estimatedSmile! > 0.3) return 'neutral';
    return 'sad';
  }
}

class ImageAnalyzerService {
  late FaceDetector _faceDetector;
  late ImageLabeler _imageLabeler;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableClassification: true,
      ),
    );
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions());
    _initialized = true;
  }

  Future<ImageProfile> analyzeImage(String imagePath) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final inputImage = InputImage.fromFilePath(imagePath);

      final List<Face> faces = await _faceDetector.processImage(inputImage);

      final List<ImageLabel> labels = await _imageLabeler.processImage(
        inputImage,
      );

      if (faces.isEmpty) {
        return ImageProfile(
          faceDetected: false,
          labels: labels.map((l) => l.label).take(5).toList(),
        );
      }

      final face = faces.first;

      final profile = ImageProfile(
        faceDetected: true,
        estimatedSmile: face.smilingProbability,
        estimatedLeftEyeOpen: face.leftEyeOpenProbability,
        estimatedRightEyeOpen: face.rightEyeOpenProbability,
        headEulerAngleY: face.headEulerAngleY,
        headEulerAngleZ: face.headEulerAngleZ,
        labels: labels.map((l) => l.label).take(10).toList(),
      );

      return profile;
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      return ImageProfile(faceDetected: false);
    }
  }

  Future<void> dispose() async {
    if (_initialized) {
      await _faceDetector.close();
      await _imageLabeler.close();
      _initialized = false;
    }
  }
}
