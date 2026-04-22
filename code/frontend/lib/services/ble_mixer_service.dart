import '../models/drink.dart';
import 'mixer_service.dart';
import 'ble_service.dart';

/// Sends drink order as "mix_a_b_c_d" (ml per pump) and waits for "mix_ok".
class BleMixerService implements MixerService {
  final BleService _ble;
  BleMixerService([BleService? ble]) : _ble = ble ?? BleService.instance;

  @override
  Future<void> orderDrink(Drink drink) async {
    final p = drink.pumpAmounts;
    await _ble.send('mix_${p[0]}_${p[1]}_${p[2]}_${p[3]}');
    await _ble.waitForMessage('mix_ok');
  }
}
