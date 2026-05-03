import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Represents analyzed image features.
class ImageProfile {
  final bool faceDetected;
  final double? estimatedSmile; // 0.0-1.0
  final double? estimatedLeftEyeOpen; // 0.0-1.0
  final double? estimatedRightEyeOpen; // 0.0-1.0
  final double? headEulerAngleY; // Rotation left-right
  final double? headEulerAngleZ; // Rotation tilt
  final List<String> labels; // Image labels (colors, objects, mood)

  ImageProfile({
    required this.faceDetected,
    this.estimatedSmile,
    this.estimatedLeftEyeOpen,
    this.estimatedRightEyeOpen,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.labels = const [],
  });

  /// Check if face shows smiling expression
  bool get isSmiling => estimatedSmile != null && estimatedSmile! > 0.4;

  /// Check if face is neutral/sad
  bool get isNeutralOrSad => !isSmiling;

  /// Get emotion based on smile level
  String get emotion {
    if (estimatedSmile == null) return 'unknown';
    if (estimatedSmile! > 0.6) return 'happy';
    if (estimatedSmile! > 0.3) return 'neutral';
    return 'sad';
  }
}

/// Service for analyzing images using Google ML Kit.
/// Extracts face features, landmarks, and image labels.
class ImageAnalyzerService {
  late FaceDetector _faceDetector;
  late ImageLabeler _imageLabeler;
  bool _initialized = false;

  /// Initialize detectors
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

  /// Analyze image at given path and extract features.
  Future<ImageProfile> analyzeImage(String imagePath) async {
    try {
      // Ensure initialized
      if (!_initialized) {
        await initialize();
      }

      final inputImage = InputImage.fromFilePath(imagePath);

      // Detect faces
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      // Get image labels
      final List<ImageLabel> labels = await _imageLabeler.processImage(
        inputImage,
      );

      if (faces.isEmpty) {
        // No face detected - return generic profile
        return ImageProfile(
          faceDetected: false,
          labels: labels.map((l) => l.label).take(5).toList(),
        );
      }

      // Analyze first (closest) face
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

  /// Cleanup resources
  Future<void> dispose() async {
    if (_initialized) {
      await _faceDetector.close();
      await _imageLabeler.close();
      _initialized = false;
    }
  }
}
