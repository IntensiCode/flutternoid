import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart' hide IterableExtension;
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:kart/kart.dart';
import 'package:supercharged/supercharged.dart';

import '../core/common.dart';
import '../core/messaging.dart';
import '../core/random.dart';
import '../util/auto_dispose.dart';
import '../util/delayed.dart';
import '../util/extensions.dart';
import '../util/on_message.dart';
import '../util/tiled_extensions.dart';
import 'brick.dart';
import 'extra_id.dart';
import 'game_context.dart';
import 'game_messages.dart';
import 'game_phase.dart';
import 'player.dart';
import 'wall.dart';

typedef Row = List<Brick?>;

enum LevelState {
  waiting,
  appearing,
  active,
  defeated,
}

enum SpawnMode {
  none,
  once_per_color,
  random,
}

class Level extends PositionComponent with AutoDispose, GameContext, HasPaint {
  late final TexturePackerSpriteSheet sprites;

  final brick_rows = <Row>[];
  final enemies = <String>[];
  final max_concurrent_enemies = 2;

  int get level_number_starting_at_1 => this.model.state.level_number_starting_at_1;

  var state = LevelState.waiting;
  double state_progress = 0.0;

  SpawnMode spawn_mode = SpawnMode.none;
  bool boss_level = false;

  late double level_time = configuration.level_time;

  double _re_sweep = 10.0;

  (int, TiledComponent)? _level_data;

  bool get has_background => background != null;

  TileLayer? get background => _level_data?.$2.tileMap.getLayer('background') as TileLayer?;

  TiledMap? get map => _level_data?.$2.tileMap.map;

  Vector2? get doh {
    final layer = _level_data?.$2.tileMap.getLayer('doh') as ObjectGroup?;
    final doh = layer?.objects.singleOrNull;
    if (doh == null) return null;
    return Vector2(doh.x + doh.width / 3, doh.y - doh.height / 2);
  }

  Iterable<Brick> get active_bricks => bricks.where((it) => !it.destroyed);

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

  void _reset({bool full_clear = true}) {
    removeAll(children); // TODO?
    brick_rows.clear(); // TODO?

    state_progress = 0;
    state = LevelState.waiting;
    opacity = 0.0;

    boss_level = false;
    spawn_mode = SpawnMode.none;
    _re_sweep = 10.0;

    if (full_clear) {
      logInfo('enemies clear now');
      enemies.clear();
      level_time = configuration.level_time;
    }
  }

  // Component

  @override
  onLoad() async {
    super.onLoad();

    priority = 2;

    paint = pixelPaint();

    sprites = atlas.sheetIWH('game_blocks.png', visual.brick_width, visual.brick_height, spacing: 1);

    _batch = SpriteBatch(sprites.image, useAtlas: !kIsWeb);

    onMessage<EnterRound>((_) => _reset());
    onMessage<LevelComplete>((_) => _reset(full_clear: false));
    onMessage<LoadLevel>((_) => _load_level());
    onMessage<PlayerReady>((_) => _sweep_level());
  }

  void _sweep_level({bool extras_only = false}) {
    double sweep_delay = 0;
    for (final (idx, row) in brick_rows.indexed) {
      sweep_delay = idx * 0.04;
      for (final brick in row) {
        if (brick == null || brick.indestructible) continue;
        if (brick.extra_id?.isNotEmpty == true) {
          brick.sweep(sweep_delay + 0.5);
        } else if (!extras_only) {
          brick.sweep(sweep_delay);
        }
        sweep_delay += 0.01;
      }
    }
  }

  Future<bool> preload_level() async {
    final which = level_number_starting_at_1.toString().padLeft(2, '0');

    try {
      final TiledComponent level_data = await TiledComponent.load(
        'level$which.tmx',
        Vector2(12.0, 6.0),
        layerPaintFactory: (it) => pixelPaint(),
        bundle: game.assets.bundle,
      );
      _level_data = (level_number_starting_at_1, level_data);
      return true;
    } catch (e) {
      logError('failed to load level $which: $e');
      sendMessage(GameOver());
      return false;
    }
  }

  void _load_level() async {
    logInfo('load level $level_number_starting_at_1');

    state_progress = 0;
    state = LevelState.waiting;
    opacity = 0.0;

    removeAll(children);

    if (_level_data == null || _level_data?.$1 != level_number_starting_at_1) {
      final which = level_number_starting_at_1.toString().padLeft(2, '0');
      try {
        final TiledComponent level_data = await TiledComponent.load(
          'level$which.tmx',
          Vector2(12.0, 6.0),
          layerPaintFactory: (it) => pixelPaint(),
        );
        _level_data = (level_number_starting_at_1, level_data);
      } catch (e) {
        logError('failed to load level $which: $e');
        sendMessage(GameOver());
        return;
      }
    }

    final level_data = _level_data!.$2;
    level_time = level_data.intOptProp('level_time')?.toDouble() ?? configuration.level_time;

    brick_rows.clear();

    final width = visual.brick_width.toDouble();
    final height = visual.brick_height.toDouble();

    final block_rows = (level_data.getLayer('blocks') as TileLayer).data!.slices(15);
    final extra_rows = (level_data.getLayer('extras') as TileLayer?)?.data?.slices(15);
    final map = level_data.tileMap.map;

    spawn_mode = level_data.spawn_mode;

    for (var (y, row) in block_rows.indexed) {
      final bricks = <Brick?>[];
      for (var (x, it) in row.indexed) {
        final topLeft = Vector2(x * width, y * height);
        final bottomRight = topLeft + Vector2(width, height);
        final brick = it == 0 ? null : Brick(BrickId.values[it - 1], topLeft, bottomRight);
        bricks.add(brick);

        if (brick == null) continue;
        await add(brick);

        final extra = extra_rows?.getOrNull(y)?.getOrNull(x);
        if (extra == null) continue;

        final id = map.tileByGid(extra)!.localId;
        if (id == -1) continue;
        brick.extra_id = {ExtraId.values[id ~/ 9]};
      }
      brick_rows.add(bricks);
    }

    logInfo('spawn mode: $spawn_mode');

    final Map<BrickId, List<Brick>> by_color = bricks.groupBy((it) => it.id);
    if (spawn_mode == SpawnMode.once_per_color) {
      logInfo('once per color extra');
      for (final it in by_color.entries) {
        final which = it.value.whereNot((it) => it.extra_id != null).toList().random(rng);
        which.extra_id = it.key.extras;
      }
    }
    if (spawn_mode == SpawnMode.random) {
      logInfo('random extras');
      final percentage = level_data.intOptProp('percentage') ?? 10;
      for (final it in by_color.entries) {
        final selection = [...it.value];
        selection.shuffle(rng);
        final count = selection.length * percentage ~/ 100;
        selection.take(count).forEach((it) => it.extra_id = it.id.extras);
      }
    }

    enemies.clear();
    enemies.addAll(['globolus', 'crystal', 'globolus', 'crystal']);

    const outset = 2.0;
    final size = visual.game_pixels;
    await add(Wall(hull: [
      Vector2(-outset - 32, -outset - 32),
      Vector2(-outset - 32, -outset),
      Vector2(size.x + outset + 32, -outset),
      Vector2(size.x + outset + 32, -outset - 32),
    ]));
    await add(Wall(hull: [
      Vector2(-outset - 32, -outset),
      Vector2(-outset, -outset),
      Vector2(-outset, size.y * 2),
      Vector2(-outset - 32, size.y * 2),
    ]));
    await add(Wall(hull: [
      Vector2(size.x + outset, -outset),
      Vector2(size.x + outset + 32, -outset),
      Vector2(size.x + outset + 32, size.y * 2),
      Vector2(size.x + outset, size.y * 2),
    ]));

    // doh/boss level
    if (bricks.isEmpty) {
      enemies.clear();
      boss_level = true;
    }

    sendMessage(LevelDataAvailable());

    add(Delayed(0.5, () {
      state = LevelState.appearing;
      state_progress = 0;
    }));
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
    state_progress += dt * 2;
    if (state_progress >= 1.0) {
      state_progress = 1.0;
      state = LevelState.active;
      sendMessage(LevelReady());
    }
  }

  void _on_active(double dt) {
    if (player.state == PlayerState.playing && phase == GamePhase.game_on) {
      level_time -= min(level_time, dt);
    }
    _re_sweep -= min(_re_sweep, dt);
    if (_re_sweep <= 0) {
      _re_sweep = 10.0;
      _sweep_level();
    }
    for (var row in brick_rows) {
      for (var x = 0; x < row.length; x++) {
        final brick = row[x];
        if (brick == null) continue;
        if (brick.sweep_delay > 0) {
          brick.sweep_delay -= min(brick.sweep_delay, dt);
          if (brick.sweep_delay <= 0) brick.sweep_progress = 1.0;
        }
        if (brick.sweep_progress > 0) {
          brick.sweep_progress -= min(brick.sweep_progress, dt * 4);
        }
        if (brick.hit_highlight > 0) brick.hit_highlight -= min(brick.hit_highlight, dt);
        if (brick.destroyed && brick.destroy_progress < 1.0) brick.destroy_progress += dt * 4;
        if (brick.destroyed && !brick.spawned) {
          model.state.score += (brick.id.score * (1 + level_number_starting_at_1 * 0.2)).round();
          if (brick.extra_id != null) {
            // logInfo('brick destroyed - extra id: ${brick.extra_id}');
            sendMessage(SpawnExtraFromBrick(brick));
          }
          brick.spawned = true;
          brick.removeFromParent(); // this is the body only - we still render the destroy animation below
        }
        if (brick.gone) row[x] = null;
      }
    }
    if (!boss_level && brick_rows.every((it) => it.every((it) => it == null || !it.counts))) {
      sendMessage(LevelComplete());
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

    for (var (y, row) in brick_rows.indexed) {
      for (var (x, brick) in row.indexed) {
        if (brick == null) continue;

        Sprite sprite;
        if (brick.destroyed) {
          final progress = brick.destroy_progress.clamp(0.0, 1.0);
          final frame = (sprites.columns - 1) * progress;
          sprite = sprites.getSpriteById(15 + frame.round().clamp(0, sprites.columns));
        } else if (brick.hit_highlight > 0) {
          sprite = sprites.getSpriteById(15);
        } else {
          sprite = sprites.getSpriteById(brick.id.index);
        }

        final trans = _cached_transforms[x + y * 15] ??= brick.topLeft.transform;
        _batch.addTransform(source: sprite.src, transform: trans);

        if (brick.sweep_progress > 0) {
          final progress = 1 - brick.sweep_progress.clamp(0.0, 1.0);
          final frame = (sprites.columns - 1) * progress;
          sprite = sprites.getSpriteById(25 + frame.round().clamp(0, sprites.columns));
          _batch.addTransform(source: sprite.src, transform: trans);
        }
      }
    }

    _batch.render(canvas, paint: _batch_paint);
    _batch.clear();
  }

  final _batch_paint = pixelPaint();

  final _cached_transforms = <int, RSTransform>{};

  late final SpriteBatch _batch;
}

extension on TiledComponent {
  SpawnMode get spawn_mode {
    var spawn_mode = stringOptProp('spawn_mode');
    if (spawn_mode == null) {
      final extra_rows = getLayer('extras') as TileLayer?;
      final got_extras = extra_rows?.data?.any((it) => it != 0) ?? false;
      spawn_mode ??= got_extras ? 'none' : 'once_per_color';
      logInfo('level default spawn mode: $spawn_mode from extras? $got_extras');
    } else {
      logInfo('level defines spawn mode: $spawn_mode');
    }
    return SpawnMode.values.firstWhere((it) => it.name == spawn_mode);
  }
}

extension Vector2Extensions on Vector2 {
  RSTransform get transform => RSTransform.fromComponents(
        rotation: 0,
        scale: 1.0,
        anchorX: 0,
        anchorY: 0,
        translateX: x,
        translateY: y,
      );
}
