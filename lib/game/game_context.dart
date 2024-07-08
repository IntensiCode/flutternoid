import 'package:flame/components.dart';
import 'package:flutternoid/game/game_controller.dart';
import 'package:flutternoid/game/game_phase.dart';

import '../input/keys.dart';
import 'flash_text.dart';
import 'game_configuration.dart';
import 'game_screen.dart';
import 'game_state.dart';
import 'level.dart';
import 'player.dart';
import 'visual_configuration.dart';

extension ComponentExtensions on Component {
  GameScreen get game {
    final it = findParent<GameScreen>(includeSelf: true) ?? findParent<GameController>(includeSelf: true)?.game;
    if (it != null) return it;
    throw 'no game found in $this';
  }

  GameConfiguration get configuration => GameConfiguration.instance;

  VisualConfiguration get visual => VisualConfiguration.instance;

  GamePhase get phase => game.phase;

  Keys get keys => game.keys;

  GameState get state => game.state;

  Level get level => game.level;

  FlashText get flash_text => game.flash_text;

  Player get player => game.player;

  Iterable<T> top_level_children<T extends Component>() => game.children.whereType<T>();

  spawn_top_level<T extends Component>(T component) => game.add(component);
}
