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

mixin GameContext on Component {
  GameScreen? _model;
  Level? _level;
  Player? _player;

  GameScreen get model {
    final it = _model ??
        findParent<GameScreen>(includeSelf: true) ?? //
        findParent<GameController>(includeSelf: true)?.model;
    if (it != null) return it;
    throw 'no game found in $this';
  }

  GameConfiguration get configuration => GameConfiguration.instance;

  VisualConfiguration get visual => VisualConfiguration.instance;

  GamePhase get phase => model.phase;

  Keys get keys => model.keys;

  GameState get game_state => model.state;

  Level get level => _level ??= model.level;

  Player get player => _player ??= model.player;

  Iterable<T> top_level_children<T extends Component>() => model.children.whereType<T>();

  spawn_top_level<T extends Component>(T component) => model.add(component);
}
