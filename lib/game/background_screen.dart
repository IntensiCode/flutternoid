import 'package:flame/components.dart';

import '../core/functions.dart';
import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/delayed.dart';
import '../util/extensions.dart';
import 'game_context.dart';

class BackgroundScreen extends PositionComponent with AutoDispose, GameScriptFunctions {
  @override
  onLoad() async {
    position.setFrom(visual.background_offset);

    final level = game.level.level_number_starting_at_1;
    const number_of_backgrounds = 8;
    final background_index = (level - 1) % number_of_backgrounds;

    final backgrounds = await sheetIWH('game_backgrounds.png', 32, 32);
    final background = backgrounds.getSpriteById(background_index);

    for (var y = 0; y < 6; y++) {
      for (var x = 0; x < 6; x++) {
        spriteSXY(background, x * 32.0 + 4, y * 32.0 + 9, Anchor.topLeft).opacity = 0;
      }
    }
    fadeInDeep(seconds: 2.0);
    add(Delayed(2, () {
      for (final it in children.whereType<SpriteComponent>()) {
        it.scale.setAll(1.005);
      }
    }));
  }
}
