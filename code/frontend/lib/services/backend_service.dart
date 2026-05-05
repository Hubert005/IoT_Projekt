import '../models/round_result.dart';

/// Interface for game backend communication.
abstract class BackendService {
  Future<void> startGame();
  Future<RoundResult> getRoundResult(int round);
}
