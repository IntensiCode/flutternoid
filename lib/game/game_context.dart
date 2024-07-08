import 'package:flame/components.dart';

import '../input/keys.dart';
import 'flash_text.dart';
import 'game_configuration.dart';
import 'game_screen.dart';
import 'level.dart';
import 'player.dart';
import 'visual_configuration.dart';

extension ComponentExtensions on Component {
  GameScreen get game => findParent<GameScreen>(includeSelf: true)!;

  GameConfiguration get configuration => GameConfiguration.instance;

  VisualConfiguration get visual => VisualConfiguration.instance;

  Keys get keys => game.keys;

  Level get level => game.level;

  FlashText get flash_text => game.flash_text;

  Player get player => game.player;

  Iterable<T> top_level_children<T extends Component>() => game.children.whereType<T>();

  spawn_top_level<T extends Component>(T component) => game.add(component);
}
