import '../engine/move_recorder.dart';

class ReplayRecorder {
  final List<MoveRecord> _moves = [];

  void addMove(MoveRecord move) => _moves.add(move);

  List<MoveRecord> get moves => List.unmodifiable(_moves);

  void clear() => _moves.clear();
}
