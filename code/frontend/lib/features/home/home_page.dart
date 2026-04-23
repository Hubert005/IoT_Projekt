import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iot_drink_mixer/core/theme/app_text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
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
  static const String _prefsBaseUrlKey = 'wifi_base_url';
  static const String _defaultBaseUrl = 'http://192.168.178.50';

  int _navIndex = 0;
  String _baseUrl = _defaultBaseUrl;
  String _wifiInfo = 'Tippen zum Einrichten';
  bool _wifiConnected = false;

  @override
  void initState() {
    super.initState();
    _loadAndCheckWifi();
  }

  Future<void> _loadAndCheckWifi() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsBaseUrlKey);
    if (saved != null && saved.isNotEmpty) {
      _baseUrl = saved;
    }

    final ok = await _ping(_baseUrl);
    if (!mounted) return;

    setState(() {
      _wifiConnected = ok;
      _wifiInfo = ok ? 'Verbunden: $_baseUrl' : 'Nicht erreichbar: $_baseUrl';
    });
  }

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
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _WifiConfigDialog(initialUrl: _baseUrl),
    );

    if (value == null || value.isEmpty) return;

    final ok = await _ping(value);
    if (!mounted) return;

    setState(() {
      _baseUrl = value;
      _wifiConnected = ok;
      _wifiInfo = ok ? 'Verbunden: $value' : 'Nicht erreichbar: $value';
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsBaseUrlKey, value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'WLAN verbunden' : 'IP gespeichert, aber /api/ping nicht erreichbar')),
    );
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
            wifiInfo: _wifiInfo,
            connected: _wifiConnected,
            onTap: _configureWifi,
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
              MaterialPageRoute(builder: (_) => const PhotoCapturePage()),
            ),
          ),
        ),
      ],
    );
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
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Arduino WLAN Adresse', style: TextStyle(color: Colors.white)),
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
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Speichern & Testen'),
        ),
      ],
    );
  }
}
