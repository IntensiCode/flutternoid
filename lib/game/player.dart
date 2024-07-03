import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../core/messaging.dart';
import '../input/keys.dart';
import '../util/debug.dart';
import '../util/extensions.dart';
import 'ball.dart';
import 'game_context.dart';
import 'game_object.dart';

class PlayerReady with Message {}

enum PlayerState {
  gone,
  entering,
  playing,
  leaving,
  exploding,
  ;

  static PlayerState from(final String name) => PlayerState.values.firstWhere((e) => e.name == name);
}

enum BatMode {
  normal1,
  catcher1,
  laser1,
  normal2,
  catcher2,
  laser2,
  normal3,
  catcher3,
  laser3,
}

class Player extends Component with HasPaint, GameObject {
  late final Keys _keys;
  late final SpriteSheet sprites;
  late final SpriteSheet explosion;
  late final Vector2 position;

  var state = PlayerState.entering;
  var state_progress = 0.0;

  var bat_mode = BatMode.catcher3;

  bool get hard_edge => (bat_mode.index % 3) == 2;
  double get bat_edge => (bat_mode.index % 3) == 2 ? 2 : 4;
  double get bat_width => 26 + bat_mode.index ~/ 3 * 4 - 2;
  double bat_height = 6;

  double x_speed = 0;

  // Component

  @override
  onLoad() async {
    priority = 1;

    paint = pixelPaint();

    _keys = keys;
    sprites = await sheetIWH('game_bat.png', 36, 8, spacing: 1, margin: 1);
    explosion = await sheetIWH('game_explosion.png', 32, 32);
    position = Vector2(visual.game_pixels.x / 2, visual.game_pixels.y * 0.9);

    add(DebugText(
      text: () => 'pp: ${position.x.toStringAsFixed(2)}, ${position.y.toStringAsFixed(2)}',
      position: Vector2(visual.game_pixels.x, visual.game_pixels.y - 2),
      anchor: Anchor.bottomRight,
    ));
    add(DebugText(
      text: () => 'ps: ${x_speed.toStringAsFixed(2)}',
      position: Vector2(visual.game_pixels.x, visual.game_pixels.y - 8),
      anchor: Anchor.bottomRight,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    switch (state) {
      case PlayerState.gone:
        break;
      case PlayerState.entering:
        _on_entering(dt);
        break;
      case PlayerState.leaving:
        _on_leaving(dt);
        break;
      case PlayerState.exploding:
        _on_exploding(dt);
        break;
      case PlayerState.playing:
        _on_playing_move(dt);
        _on_playing_fire(dt);
        break;
    }
  }

  void _on_entering(double dt) {
    state_progress += dt;
    if (state_progress > 1.0) {
      paint.color = white;
      state_progress = 1.0;
      state = PlayerState.playing;
      sendMessage(PlayerReady());
    }
  }

  void _on_leaving(double dt) {
    state_progress -= dt;
    if (state_progress < 0.0) {
      paint.color = transparent;
      state_progress = 0.0;
      state = PlayerState.gone;
    }
  }

  void _on_exploding(double dt) {
    state_progress += dt;
    if (state_progress > 1.0) {
      state_progress = 0.0;
      state = PlayerState.gone;
    }
  }

  final _acceleration = 1200;
  final _deceleration = 1500;
  final _max_speed = 250.0;

  void _on_playing_move(double dt) {
    if (_keys.check(GameKey.left)) {
      if (x_speed > 0) x_speed -= _deceleration * dt;
      x_speed -= _acceleration * dt;
    } else if (_keys.check(GameKey.right)) {
      if (x_speed < 0) x_speed += _deceleration * dt;
      x_speed += _acceleration * dt;
    } else {
      if (x_speed < 0) x_speed += _deceleration * dt;
      if (x_speed > 0) x_speed -= _deceleration * dt;
      if (x_speed.abs() < _deceleration * dt) x_speed = 0;
    }
    if (x_speed.abs() > _max_speed) {
      x_speed = x_speed.sign * _max_speed;
    }

    position.x += x_speed * dt;

    final x_stop = bat_width / 2;
    if (position.x < x_stop) {
      position.x = x_stop;
    }
    if (position.x > visual.game_pixels.x - x_stop) {
      position.x = visual.game_pixels.x - x_stop;
    }
  }

  void _on_playing_fire(double dt) {
    if (_keys.check_and_consume(GameKey.fire1)) {
      final caught = balls.where((it) => it.state == BallState.caught);
      for (final it in caught) {
        it.push(x_speed * 0.5, -_max_speed * 0.5);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    switch (state) {
      case PlayerState.gone:
        break;
      case PlayerState.entering:
        paint.opacity = state_progress;
        _render_bat(canvas);
        break;
      case PlayerState.leaving:
        paint.opacity = state_progress;
        _render_bat(canvas);
        break;
      case PlayerState.exploding:
        paint.opacity = 1;

        final frame = (state_progress * (explosion.columns - 1)).round();
        if (frame < 5) _render_bat(canvas);
        explosion.getSpriteById(frame).render(canvas, position: position, overridePaint: paint, anchor: Anchor.center);
        break;
      case PlayerState.playing:
        _render_bat(canvas);
        break;
    }
  }

  void _render_bat(Canvas canvas) {
    sprites
        .getSpriteById(bat_mode.index)
        .render(canvas, position: position, overridePaint: paint, anchor: Anchor.center);
  }

  // HasGameData

  @override
  void load_state(GameData data) {}

  @override
  GameData save_state(GameData data) => throw UnimplementedError();
}
