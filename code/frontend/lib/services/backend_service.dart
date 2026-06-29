import '../models/round_result.dart';

/// Interface for game backend communication.
abstract class BackendService {
  Future<void> startGame();
  Future<RoundResult> getRoundResult(int round);

  /// Acknowledge the round and ask the backend for the next one.
  Future<void> continueSeries();

  /// Tell the backend the series is decided; no further rounds.
  Future<void> endSeries();
}
