import 'package:flame/components.dart';

import '../core/common.dart';
import '../input/keys.dart';
import 'flash_text.dart';
import 'game_controller.dart';
import 'level.dart';
import 'player.dart';
import 'visual_configuration.dart';

// just to make jumping here easier
class GameContext {}

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

class TriggerPlasmaBlast with Message {
  final Vector2 center;

  TriggerPlasmaBlast(this.center);
}

extension ComponentExtensions on Component {
  GameController get model => findParent<GameController>(includeSelf: true)!;

  VisualConfiguration get visual => VisualConfiguration.instance;

  Keys get keys => model.keys;

  Level get level => model.level;

  FlashText get flash_text => model.flash_text;

  Player get player => model.player;
}
