import 'package:flame/components.dart';

import '../input/keys.dart';
import 'game_configuration.dart';
import 'game_controller.dart';
import 'game_phase.dart';
import 'game_screen.dart';
import 'game_state.dart';
import 'level.dart';
import 'player.dart';
import 'visual_configuration.dart';

extension ComponentExtensions on Component {
  GameScreen get model {
    final it = findParent<GameScreen>(includeSelf: true) ?? findParent<GameController>(includeSelf: true)?.model;
    if (it != null) return it;
    throw 'no game found in $this';
  }

  GameConfiguration get configuration => GameConfiguration.instance;

  VisualConfiguration get visual => VisualConfiguration.instance;

  GamePhase get phase => model.phase;

  Keys get keys => model.keys;

  GameState get state => model.state;

  Level get level => model.level;

  Player get player => model.player;

  Iterable<T> top_level_children<T extends Component>() => model.children.whereType<T>();

  spawn_top_level<T extends Component>(T component) => model.add(component);
}
