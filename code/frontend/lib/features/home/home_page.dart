import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:iot_drink_mixer/core/theme/app_text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../main.dart';
import '../../services/ble_connection.dart';
import '../../services/connection_mode.dart';
import '../game/photo_capture_page.dart';
import '../recipes/recipes_page.dart';
import 'components/bottom_nav_item.dart';
import 'components/home_status_row.dart';
import 'components/next_action_card.dart';
import 'components/start_game_button.dart';

enum _LinkState { initial, connected, unreachable }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _prefsBaseUrlKey = 'wifi_base_url';
  static const String _defaultBaseUrl = 'http://192.168.178.50';

  int _navIndex = 0;

  ConnectionMode _mode = ConnectionMode.wifi;
  String _baseUrl = _defaultBaseUrl;
  _LinkState _linkState = _LinkState.initial;
  bool _connected = false;
  bool _busy = false;
  String? _bleDeviceLabel;

  @override
  void initState() {
    super.initState();
    _loadAndCheck();
  }

  Future<void> _loadAndCheck() async {
    _mode = await ConnectionModeStore.load();

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsBaseUrlKey);
    if (saved != null && saved.isNotEmpty) _baseUrl = saved;

    if (!mounted) return;
    setState(() {});

    if (_mode == ConnectionMode.wifi) {
      final ok = await _ping(_baseUrl);
      if (!mounted) return;
      setState(() {
        _connected = ok;
        _linkState = ok ? _LinkState.connected : _LinkState.unreachable;
      });
    } else {
      // Im BLE-Modus nicht automatisch verbinden – Nutzer tippt auf
      // die Karte, dann wird gescannt.
      setState(() {
        _connected = BleConnection.instance.isConnected;
        _linkState =
            _connected ? _LinkState.connected : _LinkState.initial;
      });
    }
  }

  // ---------- WiFi ----------

  Future<bool> _ping(String baseUrl) async {
    try {
      final root = Uri.parse(baseUrl);
      final uri = root.replace(path: '/api/ping');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode < 200 || res.statusCode >= 300) return false;
      final body = jsonDecode(res.body);
      return body is Map<String, dynamic> && body['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _configureWifi() async {
    final l10n = AppLocalizations.of(context)!;
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _WifiConfigDialog(initialUrl: _baseUrl),
    );

    if (value == null || value.isEmpty) return;

    setState(() => _busy = true);
    final ok = await _ping(value);
    if (!mounted) return;

    setState(() {
      _busy = false;
      _baseUrl = value;
      _connected = ok;
      _linkState = ok ? _LinkState.connected : _LinkState.unreachable;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsBaseUrlKey, value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? l10n.wifiConnectedSnackbar : l10n.wifiIpSavedNotReachable,
        ),
      ),
    );
  }

  // ---------- BLE ----------

  Future<void> _connectBle() async {
    final l10n = AppLocalizations.of(context)!;
    if (_busy) return;
    setState(() => _busy = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.bleConnectingSnackbar)),
    );

    bool ok = false;
    try {
      ok = await BleConnection.instance.connect();
      if (ok) {
        final pong = await BleConnection.instance.ping();
        ok = pong;
      }
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _connected = ok;
      _linkState = ok ? _LinkState.connected : _LinkState.unreachable;
      _bleDeviceLabel =
          ok ? (BleConnection.instance.connectedDeviceId ?? 'ESP32') : null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.bleConnectedSnackbar : l10n.bleConnectFailed),
      ),
    );
  }

  Future<void> _disconnectBle() async {
    await BleConnection.instance.disconnect();
    if (!mounted) return;
    setState(() {
      _connected = false;
      _linkState = _LinkState.initial;
      _bleDeviceLabel = null;
    });
  }

  // ---------- Mode-Toggle ----------

  Future<void> _toggleMode() async {
    final next =
        _mode == ConnectionMode.wifi ? ConnectionMode.ble : ConnectionMode.wifi;
    await ConnectionModeStore.save(next);

    // beim Wechsel BLE sauber trennen
    if (_mode == ConnectionMode.ble && BleConnection.instance.isConnected) {
      await BleConnection.instance.disconnect();
    }

    if (!mounted) return;
    setState(() {
      _mode = next;
      _connected = false;
      _linkState = _LinkState.initial;
      _bleDeviceLabel = null;
    });

    // Im WiFi-Modus direkt prüfen, im BLE-Modus auf Tap warten.
    if (_mode == ConnectionMode.wifi) {
      final ok = await _ping(_baseUrl);
      if (!mounted) return;
      setState(() {
        _connected = ok;
        _linkState = ok ? _LinkState.connected : _LinkState.unreachable;
      });
    }
  }

  void _toggleLocale() {
    localeNotifier.value = localeNotifier.value.languageCode == 'de'
        ? const Locale('en')
        : const Locale('de');
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [Expanded(child: _buildBody()), _buildBottomNav()],
        ),
      ),
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

  Widget _buildHome() {
    final l10n = AppLocalizations.of(context)!;
    final isDE = localeNotifier.value.languageCode == 'de';

    final title = _mode == ConnectionMode.wifi ? l10n.wifiStatus : l10n.bleStatus;
    final iconConnected =
        _mode == ConnectionMode.wifi ? Icons.wifi : Icons.bluetooth_connected;
    final iconDisconnected =
        _mode == ConnectionMode.wifi ? Icons.wifi_off : Icons.bluetooth_disabled;

    final statusText = switch ((_mode, _linkState)) {
      (ConnectionMode.wifi, _LinkState.initial) => l10n.wifiInfoDefault,
      (ConnectionMode.wifi, _LinkState.connected) => l10n.wifiConnected(_baseUrl),
      (ConnectionMode.wifi, _LinkState.unreachable) =>
        l10n.wifiNotReachable(_baseUrl),
      (ConnectionMode.ble, _LinkState.initial) => l10n.bleInfoDefault,
      (ConnectionMode.ble, _LinkState.connected) =>
        l10n.bleConnected(_bleDeviceLabel ?? 'ESP32'),
      (ConnectionMode.ble, _LinkState.unreachable) => l10n.bleNotFound,
    };

    final onCardTap = _busy
        ? null
        : (_mode == ConnectionMode.wifi
            ? _configureWifi
            : (_connected ? _disconnectBle : _connectBle));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appHeading,
                  style: AppTextStyles.headingUltraLarge,
                ),
              ),
              _modePill(),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _toggleLocale,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    isDE ? 'EN' : 'DE',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: HomeStatusRow(
            title: title,
            wifiInfo: statusText,
            connected: _connected,
            iconConnected: iconConnected,
            iconDisconnected: iconDisconnected,
            onTap: onCardTap,
          ),
        ),
        const SizedBox(height: 16),
        const Expanded(child: NextActionCard()),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: StartGameButton(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhotoCapturePage(mode: _mode),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _modePill() {
    final l10n = AppLocalizations.of(context)!;
    final label =
        _mode == ConnectionMode.wifi ? l10n.modeWifi : l10n.modeBle;
    final icon =
        _mode == ConnectionMode.wifi ? Icons.wifi : Icons.bluetooth;
    return Tooltip(
      message: l10n.modeSwitchHint,
      child: GestureDetector(
        onTap: _busy ? null : _toggleMode,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
            top: BorderSide(
                color: Colors.white.withValues(alpha: 0.06), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          BottomNavItem(
            icon: Icons.grid_view_rounded,
            label: l10n.navHome,
            isActive: _navIndex == 0,
            onTap: () => setState(() => _navIndex = 0),
          ),
          BottomNavItem(
            icon: Icons.menu_book_rounded,
            label: l10n.navRecipe,
            isActive: _navIndex == 1,
            onTap: () => setState(() => _navIndex = 1),
          ),
        ],
      ),
    );
  }
}

class _WifiConfigDialog extends StatefulWidget {
  final String initialUrl;

  const _WifiConfigDialog({required this.initialUrl});

  @override
  State<_WifiConfigDialog> createState() => _WifiConfigDialogState();
}

class _WifiConfigDialogState extends State<_WifiConfigDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.dialogWifiTitle,
          style: const TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'http://192.168.178.50',
          hintStyle: TextStyle(color: Colors.white38),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l10n.dialogSaveAndTest),
        ),
      ],
    );
  }
}
