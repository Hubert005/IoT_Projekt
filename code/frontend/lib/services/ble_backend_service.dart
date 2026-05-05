import '../models/gesture.dart';
import '../models/round_result.dart';
import 'backend_service.dart';
import 'ble_connection.dart';

Gesture _parseGesture(int value) => switch (value) {
  0 => Gesture.rock,
  1 => Gesture.paper,
  _ => Gesture.scissors,
};

/// BackendService-Variante, die ueber BLE mit dem ESP32 spricht.
///
/// Wire-Protokoll (matched code/backend/code_esp32-c3/src/main.cpp):
///
///   App -> ESP : start
///   ESP -> App : start_ok
///   ESP -> App : runde_<i>_<p1>_<p2>     (3 mal, push)
///   App -> ESP : runde_ok                (Quittung nach jeder Runde)
class BleBackendService implements BackendService {
  final BleConnection conn;

  BleBackendService({BleConnection? connection})
      : conn = connection ?? BleConnection.instance;

  @override
  Future<void> startGame() async {
    final r = await conn.request('start', timeout: const Duration(seconds: 6));
    if (r != 'start_ok') {
      throw StateError('Erwartet "start_ok", erhalten "$r"');
    }
  }

  @override
  Future<RoundResult> getRoundResult(int round) async {
    // ESP schickt eine Runde sobald beide Spieler ihre Buttons
    // gedrueckt haben - kann lange dauern, daher generoeses Timeout.
    final line = await conn.nextLine(timeout: const Duration(minutes: 5));

    if (!line.startsWith('runde_')) {
      throw StateError('Erwartet "runde_*", erhalten "$line"');
    }

    final parts = line.split('_');
    if (parts.length != 4) {
      throw StateError('Ungueltige Rundenantwort: "$line"');
    }

    final p1 = _parseGesture(int.parse(parts[2]));
    final p2 = _parseGesture(int.parse(parts[3]));

    // Quittung an ESP, damit er die naechste Runde startet
    await conn.send('runde_ok');

    return RoundResult(round: round, p1: p1, p2: p2);
  }
}
