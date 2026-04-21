enum Gesture { rock, paper, scissors }

extension GestureExt on Gesture {
  String get emoji => switch (this) {
        Gesture.rock => '✊',
        Gesture.paper => '🖐',
        Gesture.scissors => '✌️',
      };

  String get label => switch (this) {
        Gesture.rock => 'Rock',
        Gesture.paper => 'Paper',
        Gesture.scissors => 'Scissors',
      };

  /// Returns 1 if this wins, 2 if other wins, null for draw.
  int? versus(Gesture other) {
    if (this == other) return null;
    if ((this == Gesture.rock && other == Gesture.scissors) ||
        (this == Gesture.scissors && other == Gesture.paper) ||
        (this == Gesture.paper && other == Gesture.rock)) return 1;
    return 2;
  }
}
