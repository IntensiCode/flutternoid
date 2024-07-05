import 'package:flame/components.dart';
import 'package:flutternoid/game/ball.dart';
import 'package:flutternoid/game/flash_text.dart';

import '../input/keys.dart';
import 'game_controller.dart';
import 'level.dart';
import 'player.dart';
import 'visual_configuration.dart';

// just to make jumping here easier
class GameContext {}

extension ComponentExtensions on Component {
  GameController get model => findParent<GameController>(includeSelf: true)!;

  VisualConfiguration get visual => model.visual;

  Keys get keys => model.keys;

  Level get level => model.level;

  FlashText get flash_text => model.flash_text;

  Player get player => model.player;

  Iterable<Ball> get balls => model.children.whereType<Ball>();
}
