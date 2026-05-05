import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:iot_drink_mixer/core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../main.dart';
import '../../services/ble_connection.dart';
import '../../services/pump_config_store.dart';
import '../game/photo_capture_page.dart';
import '../recipes/recipes_page.dart';
import 'components/bottom_nav_item.dart';
import 'components/home_status_row.dart';
import 'components/next_action_card.dart';
import 'components/pump_config_button.dart';
import 'components/pump_config_sheet.dart';
import 'components/start_game_button.dart';

enum _LinkState { initial, connected, unreachable }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

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
    if (!PumpConfigStore.instance.isLoaded) {
      await PumpConfigStore.instance.load();
    }

    if (!mounted) return;
    setState(() {
      _connected = BleConnection.instance.isConnected;
      _linkState = _connected ? _LinkState.connected : _LinkState.initial;
    });
  }

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

    final statusText = switch (_linkState) {
      _LinkState.initial => l10n.bleInfoDefault,
      _LinkState.connected => l10n.bleConnected(_bleDeviceLabel ?? 'ESP32'),
      _LinkState.unreachable => l10n.bleNotFound,
    };

    final onCardTap =
        _busy ? null : (_connected ? _disconnectBle : _connectBle);

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
            title: l10n.bleStatus,
            statusInfo: statusText,
            connected: _connected,
            iconConnected: Icons.bluetooth_connected,
            iconDisconnected: Icons.bluetooth_disabled,
            onTap: onCardTap,
          ),
        ),
        const SizedBox(height: 16),
        const Expanded(child: NextActionCard()),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: PumpConfigButton(
            onTap: () => showPumpConfigSheet(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: StartGameButton(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PhotoCapturePage(),
              ),
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
