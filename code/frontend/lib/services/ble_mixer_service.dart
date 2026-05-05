import '../models/drink.dart';
import 'ble_connection.dart';
import 'mixer_service.dart';

/// Sendet den Mix-Befehl ueber BLE an das ESP32.
///
/// Wire-Protokoll (matched code/backend/code_esp32-c3/src/main.cpp):
///   App -> ESP : mix_<a>_<b>_<c>_<d>
///   ESP -> App : mix_ok | mix_err
class BleMixerService implements MixerService {
  final BleConnection conn;

  BleMixerService({BleConnection? connection})
      : conn = connection ?? BleConnection.instance;

  @override
  Future<void> orderDrink(Drink drink) async {
    final p = drink.pumpAmounts;
    final cmd = 'mix_${p[0]}_${p[1]}_${p[2]}_${p[3]}';

    // Mix kann je nach Pumpenmenge etwas dauern -> grosszuegig.
    final r = await conn.request(cmd, timeout: const Duration(seconds: 30));
    if (r != 'mix_ok') {
      throw StateError('Erwartet "mix_ok", erhalten "$r"');
    }
  }
}
