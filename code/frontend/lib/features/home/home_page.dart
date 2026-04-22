import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:iot_drink_mixer/core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../services/ble_service.dart';
import '../game/photo_capture_page.dart';
import '../recipes/recipes_page.dart';
import 'components/bottom_nav_item.dart';
import 'components/home_status_row.dart';
import 'components/next_action_card.dart';
import 'components/start_game_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;
  bool _bleConnected = false;
  String? _bleDeviceName;
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    _bleConnected = BleService.instance.isConnected;
    _bleDeviceName = BleService.instance.deviceName;
    _connSub = BleService.instance.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _bleConnected = connected;
          _bleDeviceName = connected ? BleService.instance.deviceName : null;
        });
      }
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [Expanded(child: _buildBody()), _buildBottomNav()])),
    );
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 1:
        return const RecipesPage();
      default:
        return _buildHome();
    }
  }

  // ── Home Tab ────────────────────────────────────────────────────────────

  Widget _buildHome() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: const Text('Gehirnzellen Massaker', style: AppTextStyles.headingUltraLarge),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: HomeStatusRow(
            bleConnected: _bleConnected,
            bleDeviceName: _bleDeviceName,
            onBleTap: _showBleScanSheet,
          ),
        ),
        const SizedBox(height: 16),
        const Expanded(child: NextActionCard()),
        const SizedBox(height: 28),
        if (!_bleConnected)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: OutlinedButton.icon(
              onPressed: () {
                BleService.instance.enableTestMode();
              },
              icon: const Icon(Icons.bug_report, size: 16),
              label: const Text('Test Modus (ohne ESP32)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white38,
                side: const BorderSide(color: Colors.white12),
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: StartGameButton(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PhotoCapturePage()),
            ),
          ),
        ),
      ],
    );
  }

  // ── BLE Scan Sheet ──────────────────────────────────────────────────────

  void _showBleScanSheet() {
    BleService.instance.startScan();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _BleScanSheet(),
    ).whenComplete(BleService.instance.stopScan);
  }

  // ── Bottom Nav ──────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          BottomNavItem(
            icon: Icons.grid_view_rounded,
            label: 'HOME',
            isActive: _navIndex == 0,
            onTap: () => setState(() => _navIndex = 0),
          ),
          BottomNavItem(
            icon: Icons.menu_book_rounded,
            label: 'RECIPE',
            isActive: _navIndex == 1,
            onTap: () => setState(() => _navIndex = 1),
          ),
        ],
      ),
    );
  }
}

// ── BLE Scan Bottom Sheet ─────────────────────────────────────────────────────

class _BleScanSheet extends StatefulWidget {
  const _BleScanSheet();

  @override
  State<_BleScanSheet> createState() => _BleScanSheetState();
}

class _BleScanSheetState extends State<_BleScanSheet> {
  String? _connectingId;

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _connectingId = device.remoteId.str);
    try {
      await BleService.instance.connect(device);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _connectingId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verbindung fehlgeschlagen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'BLE Gerät verbinden',
                  style: AppTextStyles.labelMedium.copyWith(fontSize: 16),
                ),
                const Spacer(),
                StreamBuilder<bool>(
                  stream: BleService.instance.isScanning,
                  builder: (_, snap) {
                    if (snap.data ?? false) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.success,
                        ),
                      );
                    }
                    return TextButton(
                      onPressed: BleService.instance.startScan,
                      child: const Text('Neu scannen'),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ScanResult>>(
              stream: BleService.instance.scanResults,
              builder: (_, snap) {
                final results = snap.data ?? [];
                if (results.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Suche nach BLE-Geräten…',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final device = results[i].device;
                      final name = device.platformName.isNotEmpty
                          ? device.platformName
                          : device.remoteId.str;
                      final connecting = _connectingId == device.remoteId.str;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.bluetooth, color: AppColors.success),
                        title: Text(name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          device.remoteId.str,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        trailing: connecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                        onTap: connecting ? null : () => _connect(device),
                      );
                    },
                  ),
                );
              },
            ),
            if (BleService.instance.isConnected) ...[
              const Divider(color: Colors.white12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bluetooth_disabled, color: Colors.redAccent),
                title: const Text('Trennen', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  await BleService.instance.disconnect();
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
