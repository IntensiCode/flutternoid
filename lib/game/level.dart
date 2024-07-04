import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:kart/kart.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../core/messaging.dart';
import '../core/random.dart';
import '../util/extensions.dart';
import '../util/tiled_extensions.dart';
import 'brick.dart';
import 'extra_id.dart';
import 'game_context.dart';
import 'game_object.dart';
import 'level_walls.dart';

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

  Iterable<Brick> get bricks sync* {
    for (final row in brick_rows) {
      for (final brick in row) {
        if (brick == null) continue;
        yield brick;
      }
    }
  }

  Brick? find_lowest_brick(Vector2 top_center, double height_below) {
    final matches = bricks
        .where((it) => !it.destroyed)
        .where((it) => it.topLeft.x <= top_center.x && it.bottomRight.x >= top_center.x)
        .where((it) => it.topLeft.y <= top_center.y + height_below && it.bottomRight.y >= top_center.y);
    if (matches.isEmpty) return null;
    return matches.reduce((a, b) => a.topLeft.y < b.topLeft.y ? a : b);
  }

  // Component

  @override
  onLoad() async {
    priority = 2;

    paint = pixelPaint();

    sprites = await sheetIWH('game_blocks.png', visual.brick_width, visual.brick_height, spacing: 1);

    final which = level_number_starting_at_1.toString().padLeft(2, '0');
    final level_data = await TiledComponent.load(
      'level$which.tmx',
      Vector2(12.0, 6.0),
      layerPaintFactory: (it) => pixelPaint(),
    );

    brick_rows.clear();

    final width = visual.brick_width.toDouble();
    final height = visual.brick_height.toDouble();

    final block_rows = (level_data.getLayer('blocks') as TileLayer).data!.slices(15);
    final extra_rows = (level_data.getLayer('extras') as TileLayer?)?.data?.slices(15);
    final map = level_data.tileMap.map;

    for (var (y, row) in block_rows.indexed) {
      final bricks = <Brick?>[];
      for (var (x, it) in row.indexed) {
        final topLeft = Vector2(x * width, y * height);
        final bottomRight = topLeft + Vector2(width, height);
        final brick = it == 0 ? null : Brick(BrickId.values[it - 1], topLeft, bottomRight);
        bricks.add(brick);

        if (brick == null) continue;
        add(brick);

        final extra = extra_rows?.getOrNull(y)?.getOrNull(x);
        if (extra == null) continue;

        final id = map.tileByGid(extra)!.localId;
        brick.extra_id = {ExtraId.values[id ~/ 9]};
      }
      brick_rows.add(bricks);
    }

    const outset = 2.0;
    final size = visual.game_pixels;
    add(Wall(start: Vector2(-outset, -outset), end: Vector2(size.x + outset, -outset)));
    add(Wall(start: Vector2(-outset, -outset), end: Vector2(-outset, size.y * 2)));
    add(Wall(start: Vector2(size.x + outset, -outset), end: Vector2(size.x + outset, size.y * 2)));
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
        if (brick.destroyed && !brick.spawned) {
          final probability = 0.05 + (brick.id.index ~/ 5) * 0.1;
          if (brick.extra_id != null || rng.nextDouble() < probability) {
            sendMessage(SpawnExtraFromBrick(brick));
          }
          brick.spawned = true;
          brick.removeFromParent();
        }
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
  void load_state(GameData data) {}

  @override
  GameData save_state(GameData data) => data;
}
