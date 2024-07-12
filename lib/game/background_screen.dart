import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flutternoid/game/game_messages.dart';
import 'package:flutternoid/util/on_message.dart';
import 'package:tiled/tiled.dart';

import '../core/functions.dart';
import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/delayed.dart';
import '../util/extensions.dart';
import 'game_context.dart';

class BackgroundScreen extends PositionComponent with AutoDispose, GameScriptFunctions, HasPaint {
  @override
  onLoad() async {
    position.setFrom(visual.background_offset);
    onMessage<LevelComplete>((_) => fadeOutDeep(and_remove: false));
    onMessage<LevelDataAvailable>((_) => _load_level());
    // onMessage<LoadLevel>((_) => _load_level());
  }

  void _load_level() async {
    logInfo('load level ${model.level.level_number_starting_at_1}');
    removeAll(children);

    final bg = level.background;
    if (bg != null) {
      await _make_tiled_background(bg);
    } else {
      await _make_default_background();
    }

    add(Delayed(0.5, () {
      fadeInDeep(seconds: 0.5);
      add(Delayed(0.5, () {
        for (final it in children.whereType<SpriteComponent>()) {
          it.scale.setAll(1.005);
        }
      }));
    }));
  }

  Future<void> _make_tiled_background(TileLayer bg) async {
    final tiles = await sheetIWH('doh_background.png', 16, 16);
    final map = level.map!;
    for (var y = 0; y < bg.height; y++) {
      for (var x = 0; x < bg.width; x++) {
        final gid = bg.tileData![y][x];
        final tile = map.tileByGid(gid.tile);
        final sprite = tiles.getSpriteById(tile!.localId);
        (await spriteSXY(sprite, x * 16.0 + 4, y * 16.0 + 9, Anchor.topLeft)).opacity = 0.0;
      }
    }
  }

  Future _make_default_background() async {
    final level = model.level.level_number_starting_at_1;
    const number_of_backgrounds = 8;
    final background_index = (level - 1) % number_of_backgrounds;

    final backgrounds = await sheetIWH('game_backgrounds.png', 32, 32);
    final background = backgrounds.getSpriteById(background_index);

    for (var y = 0; y < 6; y++) {
      for (var x = 0; x < 6; x++) {
        (await spriteSXY(background, x * 32.0 + 4, y * 32.0 + 9, Anchor.topLeft)).opacity = 0.0;
      }
    }
  }
}
