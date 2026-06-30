import 'gesture.dart';

class RoundResult {
  final int round;
  final Gesture p1;
  final Gesture p2;
  final int? winner;

  RoundResult({required this.round, required this.p1, required this.p2})
      : winner = p1.versus(p2);
}
