import 'package:shared_preferences/shared_preferences.dart';

/// Welcher Transport zum Mikrocontroller benutzt wird.
enum ConnectionMode { wifi, ble }

class ConnectionModeStore {
  static const String _key = 'connection_mode';

  static Future<ConnectionMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return raw == 'ble' ? ConnectionMode.ble : ConnectionMode.wifi;
  }

  static Future<void> save(ConnectionMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ConnectionMode.ble ? 'ble' : 'wifi');
  }
}
