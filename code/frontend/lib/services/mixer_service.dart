import '../models/drink.dart';

/// Interface for sending a drink order to the mixer / microcontroller.
abstract class MixerService {
  Future<void> orderDrink(Drink drink);
}

/// Simulates sending the order with a ~2 s delay.
class MockMixerService implements MixerService {
  @override
  Future<void> orderDrink(Drink drink) async {
    await Future.delayed(const Duration(seconds: 2));
    // ignore: avoid_print
    print('[MockMixerService] Order sent: ${drink.id}');
  }
}

// ── Real implementation stub ───────────────────────────────────────────────
// class HttpMixerService implements MixerService {
//   @override
//   Future<void> orderDrink(Drink drink) async {
//     await http.post(
//       Uri.parse('http://mixer.local/order'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(drink.toJson()),
//     );
//   }
// }
//
// class MqttMixerService implements MixerService {
//   @override
//   Future<void> orderDrink(Drink drink) async {
//     mqttClient.publish('mixer/order', jsonEncode(drink.toJson()));
//   }
// }
