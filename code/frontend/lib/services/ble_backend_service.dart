import '../models/gesture.dart';
import '../models/round_result.dart';
import 'ble_service.dart';

// ESP encodes gestures as integers: 0=rock, 1=paper, 2=scissors
Gesture _parse(int v) => switch (v) {
  0 => Gesture.rock,
  1 => Gesture.paper,
  _ => Gesture.scissors,
};

/// Receives round results via BLE in the format "runde_x_y_z":
///   x = round number, y = P1 gesture, z = P2 gesture.
/// Responds with "runde_ok" after each round.
class BleBackendService {
  final BleService _ble;
  BleBackendService([BleService? ble]) : _ble = ble ?? BleService.instance;

  Future<RoundResult> getRoundResult(int round) async {
    final msg = await _ble.waitForMessage('runde_');
    final parts = msg.split('_');
    final p1 = _parse(int.parse(parts[2]));
    final p2 = _parse(int.parse(parts[3]));
    await _ble.send('runde_ok');
    return RoundResult(round: round, p1: p1, p2: p2);
  }
}
