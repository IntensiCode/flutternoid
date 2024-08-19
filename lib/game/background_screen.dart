import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutternoid/core/common.dart';
import 'package:tiled/tiled.dart';

import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/delayed.dart';
import '../util/extensions.dart';
import '../util/on_message.dart';
import 'background_stars.dart';
import 'game_context.dart';
import 'game_messages.dart';
import 'game_phase.dart';

class BackgroundScreen extends PositionComponent with AutoDispose, GameScriptFunctions, GameContext, HasPaint {
  //
  final _stars = BackgroundStars();

  late SpriteComponent _frame;

  bool renderSnapshot = false;

  Image? _snapshot;

  final _paint = pixelPaint();

  @override
  onLoad() async {
    position.setFrom(visual.background_offset);

    onMessage<GamePhaseUpdate>((it) => renderSnapshot = it.phase == GamePhase.game_on);
    onMessage<LevelComplete>((_) => _fade_out());
    onMessage<LevelDataAvailable>((_) => _load_level());

    add(_stars);
    _stars.priority = -1;
    _stars.position.x -= 16;

    _frame = await spriteXY('skin_frame.png', 0, 0, Anchor.topLeft);
    _frame.priority = 1;
    _frame.fadeInDeep(seconds: 1);
  }

  void _fade_out() {
    for (final it in children) {
      if (it == _stars || it == _frame) continue;
      it.fadeOutDeep(seconds: 1);
    }
  }

  void _fade_in() {
    for (final it in children) {
      if (it == _stars || it == _frame) continue;
      it.fadeInDeep(seconds: 0.5);
    }
  }

  void _load_level() async {
    logInfo('load level ${model.level.level_number_starting_at_1}');

    final sprites = children.whereNot((it) => it == _stars || it == _frame);
    removeAll(sprites);

    final bg = level.background;
    if (bg != null) {
      await _make_tiled_background(bg);
    } else {
      await _make_default_background();
    }

    add(Delayed(0.5, () => _fade_in()));
  }

  Future _make_tiled_background(TileLayer bg) async {
    final tiles = atlas.sheetIWH('doh_background.png', 16, 16);
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

    final backgrounds = atlas.sheetIWH('game_backgrounds.png', 32, 32);
    final background = backgrounds.getSpriteById(background_index);

    for (var y = 0; y < 6; y++) {
      for (var x = 0; x < 6; x++) {
        (await spriteSXY(background, x * 32.0 + 4, y * 32.0 + 9, Anchor.topLeft)).opacity = 0.0;
      }
    }
  }

  @override
  void renderTree(Canvas canvas) {
    if (renderSnapshot && _snapshot == null) {
      _snapshot = _render_clean_image();
    } else if (!renderSnapshot && _snapshot != null) {
      _snapshot?.dispose();
      _snapshot = null;
    }

    final it = _snapshot ?? _render_clean_image();
    canvas.translateVector(visual.background_offset);
    canvas.drawImage(it, Offset.zero, _paint);
    canvas.translate(-visual.background_offset.x, -visual.background_offset.y);
  }

  Image _render_clean_image() {
    final recorder = PictureRecorder();
    super.renderTree(Canvas(recorder)..translate(-visual.background_offset.x, -visual.background_offset.y));
    final picture = recorder.endRecording();
    final clean = picture.toImageSync(320, 200);
    picture.dispose();
    return clean;
  }
}
