import 'common.dart';

enum GamePhase {
  start_game,
  playing_level,
  game_paused,
  game_over,
  confirm_exit,
  ;

  static GamePhase from(final String name) => GamePhase.values.firstWhere((e) => e.name == name);
}

class LevelComplete with Message {}

class GamePhaseUpdate with Message {
  final GamePhase phase;

  GamePhaseUpdate(this.phase);
}
