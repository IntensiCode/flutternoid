import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../util/extensions.dart';
import '../util/tiled_extensions.dart';
import 'brick.dart';
import 'game_context.dart';
import 'game_object.dart';

typedef Row = List<Brick?>;

enum LevelState {
  waiting,
  appearing,
  active,
  defeated,
}

class Level extends PositionComponent with GameObject, HasPaint {
  late final SpriteSheet sprites;

  final brick_rows = <Row>[];

  int level_number_starting_at_1 = 1;

  var state = LevelState.appearing;
  double state_progress = 0.0;

  Iterable<Brick> bricks() sync* {
    for (final row in brick_rows) {
      for (final brick in row) {
        if (brick == null) continue;
        yield brick;
      }
    }
  }

  // Component

  @override
  onLoad() async {
    priority = 1;

    paint = pixelPaint();

    sprites = await sheetIWH('game_blocks.png', visual.brick_width, visual.brick_height, spacing: 1);

    final map = await TiledComponent.load(
      'level01.tmx',
      Vector2(12.0, 6.0),
      layerPaintFactory: (it) => pixelPaint(),
    );

    brick_rows.clear();

    final width = visual.brick_width.toDouble();
    final height = visual.brick_height.toDouble();

    final data = (map.getLayer('blocks') as TileLayer).data!;
    final rows = data.slices(15);
    for (var (y, row) in rows.indexed) {
      final bricks = <Brick?>[];
      for (var (x, it) in row.indexed) {
        final topLeft = Vector2(x * width, y * height);
        final bottomRight = topLeft + Vector2(width, height);
        final brick = it == 0 ? null : Brick(BrickId.values[it - 1], topLeft, bottomRight);
        bricks.add(brick);
      }
      brick_rows.add(bricks);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (state) {
      case LevelState.waiting:
        break;
      case LevelState.appearing:
        _on_appearing(dt);
      case LevelState.active:
        _on_active(dt);
      case LevelState.defeated:
        break;
    }
  }

  void _on_appearing(double dt) {
    state_progress += dt;
    if (state_progress >= 1.0) {
      state_progress = 1.0;
      state = LevelState.active;
    }
  }

  void _on_active(double dt) {
    for (var row in brick_rows) {
      for (var x = 0; x < row.length; x++) {
        final brick = row[x];
        if (brick == null) continue;
        if (brick.hit_highlight > 0) brick.hit_highlight -= min(brick.hit_highlight, dt);
        if (brick.destroyed && brick.destroy_progress < 1.0) brick.destroy_progress += dt * 4;
        if (brick.gone) row[x] = null;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    switch (state) {
      case LevelState.waiting:
        break;
      case LevelState.appearing:
        _render_appearing(canvas);
      case LevelState.active:
        _render_active(canvas);
      case LevelState.defeated:
        break;
    }
  }

  void _render_appearing(Canvas canvas) {
    paint.opacity = state_progress;

    for (var row in brick_rows) {
      for (var brick in row) {
        if (brick == null) continue;
        final sprite = sprites.getSpriteById(brick.id.index);
        sprite.render(canvas, position: brick.topLeft, overridePaint: paint);
      }
    }
  }

  void _render_active(Canvas canvas) {
    paint.opacity = 1;

    for (var row in brick_rows) {
      for (var brick in row) {
        if (brick == null) continue;

        final Sprite sprite;
        if (brick.destroyed) {
          final progress = brick.destroy_progress.clamp(0.0, 1.0);
          final frame = (sprites.columns - 1) * progress;
          sprite = sprites.getSpriteById(15 + frame.round().clamp(0, sprites.columns));
        } else if (brick.hit_highlight > 0) {
          sprite = sprites.getSpriteById(15);
        } else {
          sprite = sprites.getSpriteById(brick.id.index);
        }
        sprite.render(canvas, position: brick.topLeft, overridePaint: paint);
      }
    }
  }

  // HasGameData

  @override
  void load_state(GameData data) {
//     next_tile.load_state(data['next_tile']);
//     current_tile.load_state(data['current_tile']);
//     level_number_starting_at_1 = data['level_number_starting_at_1'];
//     remaining_lines_to_clear = data['remaining_lines_to_clear'];
//     step_delay_in_seconds = data['step_delay_in_seconds'];
//     _lines_to_fill_in = data['lines_to_fill_in'];
//     _lines_fill_ticks = data['lines_fill_ticks'];
  }

  @override
  GameData save_state(GameData data) => data;
//     ..['next_tile'] = next_tile.save_state({})
//     ..['current_tile'] = current_tile.save_state({})
//     ..['level_number_starting_at_1'] = level_number_starting_at_1
//     ..['remaining_lines_to_clear'] = remaining_lines_to_clear
//     ..['step_delay_in_seconds'] = step_delay_in_seconds
//     ..['lines_to_fill_in'] = _lines_to_fill_in
//     ..['lines_fill_ticks'] = _lines_fill_ticks;
}
