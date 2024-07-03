import 'package:flame/components.dart';
import 'package:flutternoid/game/ball.dart';

import '../input/keys.dart';
import 'game_configuration.dart';
import 'game_controller.dart';
import 'level.dart';
import 'player.dart';
import 'visual_configuration.dart';

extension ComponentExtensions on Component {
  GameController get model => findParent<GameController>(includeSelf: true)!;

  GameConfiguration get configuration => model.configuration;

  VisualConfiguration get visual => model.visual;

  Keys get keys => model.keys;

  Level get level => model.level;

  Player get player => model.player;

  Iterable<Ball> get balls => model.children.whereType<Ball>();
}
