import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:iot_drink_mixer/core/theme/app_text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../main.dart';
import '../game/photo_capture_page.dart';
import '../recipes/recipes_page.dart';
import 'components/bottom_nav_item.dart';
import 'components/home_status_row.dart';
import 'components/next_action_card.dart';
import 'components/start_game_button.dart';

enum _WifiState { initial, connected, unreachable }

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
  _WifiState _wifiState = _WifiState.initial;
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
      _wifiState = ok ? _WifiState.connected : _WifiState.unreachable;
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
    final l10n = AppLocalizations.of(context)!;
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
      _wifiState = ok ? _WifiState.connected : _WifiState.unreachable;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsBaseUrlKey, value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.wifiConnectedSnackbar : l10n.wifiIpSavedNotReachable),
      ),
    );
  }

  void _toggleLocale() {
    localeNotifier.value = localeNotifier.value.languageCode == 'de'
        ? const Locale('en')
        : const Locale('de');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [Expanded(child: _buildBody()), _buildBottomNav()]),
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
    final wifiInfo = switch (_wifiState) {
      _WifiState.initial => l10n.wifiInfoDefault,
      _WifiState.connected => l10n.wifiConnected(_baseUrl),
      _WifiState.unreachable => l10n.wifiNotReachable(_baseUrl),
    };

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.appHeading, style: AppTextStyles.headingUltraLarge),
              ),
              GestureDetector(
                onTap: _toggleLocale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            wifiInfo: wifiInfo,
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

  Widget _buildBottomNav() {
    final l10n = AppLocalizations.of(context)!;
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
      title: Text(l10n.dialogWifiTitle, style: const TextStyle(color: Colors.white)),
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
