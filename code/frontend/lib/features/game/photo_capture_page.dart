import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../services/backend_service.dart';
import '../../services/drink_service.dart';
import '../../services/mixer_service.dart';
import 'components/photo_capture_header.dart';
import 'components/photo_capture_start_button.dart';
import 'components/photo_capture_step_indicator.dart';
import 'components/player_photo_card.dart';
import 'game_screen.dart';

class PhotoCapturePage extends StatefulWidget {
  const PhotoCapturePage({super.key});

  @override
  State<PhotoCapturePage> createState() => _PhotoCapturePageState();
}

class _PhotoCapturePageState extends State<PhotoCapturePage> {
  String? _p1Path;
  String? _p2Path;
  bool _isCapturing = false;

  Future<void> _capturePhoto(int player) async {
    setState(() => _isCapturing = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        setState(() {
          if (player == 1)
            _p1Path = file.path;
          else
            _p2Path = file.path;
        });
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _startGame() {
    if (_p1Path == null || _p2Path == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => GameScreen(
              player1ImagePath: _p1Path!,
              player2ImagePath: _p2Path!,
              backend: MockBackendService(),
              drinkService: MockDrinkService(),
              mixerService: MockMixerService(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bothDone = _p1Path != null && _p2Path != null;
    final p1Done = _p1Path != null;
    final p2Done = _p2Path != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              PhotoCaptureHeader(onBack: () => Navigator.pop(context)),
              const SizedBox(height: 28),
              PhotoCaptureStepIndicator(player1Done: p1Done, player2Done: p2Done),
              const SizedBox(height: 28),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: PlayerPhotoCard(
                        player: 1,
                        imagePath: _p1Path,
                        onTap: _isCapturing ? null : () => _capturePhoto(1),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: PlayerPhotoCard(
                        player: 2,
                        imagePath: _p2Path,
                        onTap: _isCapturing ? null : () => _capturePhoto(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PhotoCaptureStartButton(enabled: bothDone, onTap: _startGame),
            ],
          ),
        ),
      ),
    );
  }
}
