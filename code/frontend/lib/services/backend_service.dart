import '../models/gesture.dart';
import '../models/round_result.dart';

/// Interface for receiving round results from the Arduino / backend.
/// Swap [MockBackendService] for a real HTTP / WebSocket / MQTT implementation.
abstract class BackendService {
  Future<RoundResult> getRoundResult(int round);
}

/// Simulates Arduino sending gesture results after a ~3 s delay.
class MockBackendService implements BackendService {
  // P1 wins R1, P2 wins R2 + R3 → P2 wins series 1:2
  static const _mockRounds = [
    (Gesture.paper, Gesture.rock),
    (Gesture.rock, Gesture.paper),
    (Gesture.scissors, Gesture.rock),
  ];

  @override
  Future<RoundResult> getRoundResult(int round) async {
    await Future.delayed(const Duration(seconds: 3));
    final (p1, p2) = _mockRounds[(round - 1) % _mockRounds.length];
    return RoundResult(round: round, p1: p1, p2: p2);
  }
}