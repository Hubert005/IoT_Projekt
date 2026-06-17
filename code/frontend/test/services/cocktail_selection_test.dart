import 'package:flutter_test/flutter_test.dart';
import 'package:iot_drink_mixer/models/cocktail.dart';
import 'package:iot_drink_mixer/services/google_ml_kit_cocktail_service.dart';
import 'package:iot_drink_mixer/services/image_analyzer_service.dart';
import 'package:iot_drink_mixer/services/mock_cocktail_service.dart';

/// Fake analyzer that returns a fixed profile without touching ML Kit / native
/// platform channels.
class _FakeAnalyzer extends ImageAnalyzerService {
  final ImageProfile profile;
  _FakeAnalyzer(this.profile);

  @override
  Future<void> initialize() async {}

  @override
  Future<ImageProfile> analyzeImage(String imagePath) async => profile;
}

const _candidates = [
  CocktailData(
    id: 'fresh',
    name: 'Fresh One',
    description: '',
    pairingTags: ['happy', 'fresh', 'light', 'colorful'],
  ),
  CocktailData(
    id: 'dark',
    name: 'Dark One',
    description: '',
    pairingTags: ['dark', 'serious', 'intense'],
  ),
];

void main() {
  group('GoogleMLKitCocktailService', () {
    test('picks a candidate from the provided pool', () async {
      final service = GoogleMLKitCocktailService(
        analyzer: _FakeAnalyzer(ImageProfile(faceDetected: true, estimatedSmile: 0.9)),
      );
      final result = await service.selectCocktail(
        loserImagePath: 'x.jpg',
        candidates: _candidates,
      );
      expect(_candidates.map((c) => c.id), contains(result.id));
    });

    test('a happy face favours fresh/happy-tagged cocktails', () async {
      final service = GoogleMLKitCocktailService(
        analyzer: _FakeAnalyzer(ImageProfile(
          faceDetected: true,
          estimatedSmile: 0.9,
          estimatedLeftEyeOpen: 0.9,
          estimatedRightEyeOpen: 0.9,
        )),
      );
      final result = await service.selectCocktail(
        loserImagePath: 'x.jpg',
        candidates: _candidates,
      );
      expect(result.id, 'fresh');
    });

    test('returns the only candidate without analysing', () async {
      final service = GoogleMLKitCocktailService(
        analyzer: _FakeAnalyzer(ImageProfile(faceDetected: false)),
      );
      final result = await service.selectCocktail(
        loserImagePath: 'x.jpg',
        candidates: [_candidates.first],
      );
      expect(result.id, 'fresh');
    });
  });

  group('MockCocktailService', () {
    test('picks from the candidate pool', () async {
      final result = await MockCocktailService().selectCocktail(
        loserImagePath: 'x.jpg',
        candidates: _candidates,
      );
      expect(_candidates.map((c) => c.id), contains(result.id));
    });
  });
}
