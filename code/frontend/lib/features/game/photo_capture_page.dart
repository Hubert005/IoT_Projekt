import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../services/backend_service.dart';
import '../../services/ble_backend_service.dart';
import '../../services/ble_connection.dart';
import '../../services/ble_mixer_service.dart';
import '../../services/connection_mode.dart';
import '../../services/drink_service.dart';
import '../../services/mixer_service.dart';
import '../../services/wifi_backend_service.dart';
import '../../services/wifi_mixer_service.dart';
import 'components/photo_capture_header.dart';
import 'components/photo_capture_start_button.dart';
import 'components/photo_capture_step_indicator.dart';
import 'components/player_photo_card.dart';
import 'game_screen.dart';

class PhotoCapturePage extends StatefulWidget {
  final ConnectionMode mode;

  const PhotoCapturePage({super.key, this.mode = ConnectionMode.wifi});

  @override
  State<PhotoCapturePage> createState() => _PhotoCapturePageState();
}

class _PhotoCapturePageState extends State<PhotoCapturePage> {
  static const String _prefsBaseUrlKey = 'wifi_base_url';
  static const String _defaultBaseUrl = 'http://192.168.178.50';

  String? _p1Path;
  String? _p2Path;
  bool _isCapturing = false;
  String _lastBaseUrl = _defaultBaseUrl;
  bool _hasSavedBaseUrl = false;

  @override
  void initState() {
    super.initState();
    _loadSavedBaseUrl();
  }

  Future<void> _loadSavedBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsBaseUrlKey);
    if (saved != null && saved.isNotEmpty) {
      if (mounted) {
        setState(() {
          _lastBaseUrl = saved;
          _hasSavedBaseUrl = true;
        });
      }
    }
  }

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
          if (player == 1) {
            _p1Path = file.path;
          } else {
            _p2Path = file.path;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _startGame() async {
    if (_p1Path == null || _p2Path == null) return;

    late final BackendService backend;
    late final MixerService mixer;

    if (widget.mode == ConnectionMode.ble) {
      // Sicherstellen, dass die BLE-Verbindung steht.
      if (!BleConnection.instance.isConnected) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bleConnectingSnackbar)),
        );
        final ok = await BleConnection.instance.connect();
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.bleConnectFailed)),
          );
          return;
        }
      }
      backend = BleBackendService();
      mixer = BleMixerService();
    } else {
      String? baseUrl;
      if (_hasSavedBaseUrl) {
        baseUrl = _lastBaseUrl;
      } else {
        baseUrl = await _askWifiBaseUrl();
      }
      if (!mounted || baseUrl == null || baseUrl.isEmpty) return;
      backend = WifiBackendService(baseUrl: baseUrl);
      mixer = WifiMixerService(baseUrl: baseUrl);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          player1ImagePath: _p1Path!,
          player2ImagePath: _p2Path!,
          backend: backend,
          drinkService: MockDrinkService(),
          mixerService: mixer,
        ),
      ),
    );
  }

  Future<String?> _askWifiBaseUrl() async {
    final controller = TextEditingController(text: _lastBaseUrl);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctxL10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(ctxL10n.dialogWifiTitle,
              style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'http://192.168.178.50',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctxL10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(ctxL10n.dialogContinue),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (value != null && value.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsBaseUrlKey, value);
      if (mounted) setState(() => _lastBaseUrl = value);
    }

    return value;
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
