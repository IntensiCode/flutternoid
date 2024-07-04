import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/cupertino.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../core/soundboard.dart';
import '../util/auto_dispose.dart';
import '../util/debug.dart';
import '../util/extensions.dart';
import '../util/geom.dart';
import '../util/on_message.dart';
import 'brick.dart';
import 'extra_id.dart';
import 'game_context.dart';
import 'game_object.dart';
import 'player.dart';
import 'player_extensions.dart';

enum BallState {
  gone,
  appearing,
  caught,
  active,
}

class Ball extends Component with AutoDispose, HasPaint, GameObject {
  late final Player _player;
  late final double _half_bat_width;
  late final double _half_bat_height;
  late final SpriteSheet sprites;

  final position = Vector2.zero();
  final velocity = Vector2.zero();
  final caught_offset = Vector2(0, -3);

  var state = BallState.appearing;
  var state_progress = 0.0;
  var slow_down = 0.0;
  var disruptor = 0.0;

  bool _clear_bat = false;
  bool _lost = false;

  Ball();

  Ball.spawned(Ball origin, Vector2 velocity) {
    this.position.setFrom(origin.position);
    this.velocity.setFrom(velocity);
    this.velocity.scale(0.5);
    this.state = BallState.active;
    this.slow_down = origin.slow_down;
    this._clear_bat = origin._clear_bat;
  }

  push(double dx, double dy) {
    velocity.x += dx * 0.8;
    velocity.y += dy;
    state = BallState.active;
  }

  // Component

  @override
  onLoad() async {
    priority = 2;

    paint = pixelPaint();

    _player = player;
    _half_bat_width = _player.bat_width / 2.0;
    _half_bat_height = _player.bat_height / 2.0;

    sprites = await sheetIWH('game_ball.png', 4, 4, spacing: 2);

    add(DebugText(
      text: () => 'bp: ${position.x.toStringAsFixed(2)}, ${position.y.toStringAsFixed(2)}',
      position: Vector2(0, visual.game_pixels.y - 2),
      anchor: Anchor.bottomLeft,
    ));
    add(DebugText(
      text: () => 'bs: ${velocity.x.toStringAsFixed(2)}, ${velocity.y.toStringAsFixed(2)}',
      position: Vector2(0, visual.game_pixels.y - 8),
      anchor: Anchor.bottomLeft,
    ));
    add(DebugText(
      text: () => 'bs: ${velocity.length.toStringAsFixed(2)}',
      position: Vector2(0, visual.game_pixels.y - 14),
      anchor: Anchor.bottomLeft,
    ));
    add(DebugText(
      text: () => 'sd: ${slow_down.toStringAsFixed(2)}',
      position: Vector2(0, visual.game_pixels.y - 20),
      anchor: Anchor.bottomLeft,
    ));
  }

  @override
  void onMount() {
    super.onMount();
    onMessage<SlowDown>((it) => slow_down = configuration.slow_down_time);
    onMessage<Disruptor>((it) => disruptor = configuration.disruptor_time);
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (state) {
      case BallState.gone:
        break;
      case BallState.appearing:
        _on_appearing(dt);
      case BallState.caught:
        _on_caught(dt);
      case BallState.active:
        _on_active(dt);
    }
  }

  void _on_appearing(double dt) {
    position.setFrom(_player.position);
    position.y -= 3.0;

    state_progress += dt * 4;
    if (state_progress >= 1.0) {
      paint.opacity = 1;
      state_progress = 1.0;
      state = BallState.caught;
    } else {
      paint.opacity = state_progress;
    }
  }

  void _on_caught(double dt) {
    position.setFrom(_player.position);
    position.add(caught_offset);
    if (caught_offset.x < 0) caught_offset.x += 20 * dt;
    if (caught_offset.x > 0) caught_offset.x -= 20 * dt;
    if (caught_offset.y < -_half_bat_height) caught_offset.y += 10 * dt;
    if (caught_offset.y > -_half_bat_height) caught_offset.y -= 10 * dt;
  }

  void _on_active(double dt) {
    if (slow_down > 0) slow_down -= min(slow_down, dt);
    if (disruptor > 0) {
      disruptor -= min(disruptor, dt);
      logInfo(disruptor);
    }

    // dt = slow_down ? _apply_slow_down(dt) : dt;
    _apply_speed(dt);

    _check_brick_hit();
    // if (_speed.y.abs() < _min_speed) {
    //   _speed.y = _min_speed * -speed_y.sign;
    //   _speed.normalize();
    //   _speed.scale(speed);
    // } else {
    //   _speed.normalize();
    //   _speed.scale(speed);
    // }

    _check_bat_hit(dt);
    _check_ball_lost();
  }

  // double _apply_slow_down(double dt) {
  //   if (position.y > visual.game_pixels.y - slow_down_area) {
  //     final slow_down = position.y - (visual.game_pixels.y - slow_down_area);
  //     return dt /= 1 + slow_down / slow_down_area * 10;
  //   }
  //   // if (position.y < slow_down_area) {
  //   //   final slow_down = slow_down_area - position.y;
  //   //   return dt /= 1 + slow_down / slow_down_area * 4;
  //   // }
  //   return dt;
  // }

  static const _min_speed = 50.0;
  static const _max_speed = 150.0;
  static const _min_speed_squared = _min_speed * _min_speed;
  static const _max_speed_squared = _max_speed * _max_speed;

  static final _actual_speed = Vector2.zero();

  void _apply_speed(double dt) {
    // if (position.y > visual.game_pixels.y - 10) return;

    if (velocity.y.abs() < _min_speed * 0.9) {
      logInfo('fix min speed y $velocity');
      velocity.y = _min_speed * velocity.y.sign;
      if ((velocity.y * 100).round() == 0) velocity.y = -_min_speed;
      logInfo('speed: $velocity');
    }

    if (velocity.length2 < _min_speed_squared) {
      logInfo('fix min speed 2');
      velocity.normalize();
      velocity.scale(_min_speed);
      logInfo('speed: $velocity');
    } else if (velocity.length2 > _max_speed_squared * 1.05) {
      logInfo('fix max speed');
      velocity.normalize();
      velocity.scale(_max_speed);
      logInfo('speed: $velocity');
    }
    _actual_speed.setFrom(velocity);
    if (slow_down > 0) {
      final slow_down_pos = position.y - (visual.game_pixels.y - visual.slow_down_area);
      if (slow_down_pos > 0) {
        final factor = (slow_down_pos / visual.slow_down_area).clamp(0.0, 0.8);
        _actual_speed.scale(1 - factor);
      }
    }

    _actual_speed.scale(dt);
    position.add(_actual_speed);

    // position.x += _speed.x * dt;
    // position.y += _speed.y * dt;
    if (position.x < 0 || position.x > visual.game_pixels.x) {
      velocity.x = -velocity.x;
      soundboard.play(Sound.wall_hit);
    }
    if (position.y < 0) {
      velocity.y = -velocity.y;
      soundboard.play(Sound.wall_hit);
    }
  }

  void _check_brick_hit() {
    const threshold = 2.0;
    final contacts = <Brick>[];
    for (final brick in level.bricks()) {
      if (brick.destroyed) continue;
      if (position.x < brick.topLeft.x - threshold) continue;
      if (position.x > brick.bottomRight.x + threshold) continue;
      if (position.y < brick.topLeft.y - threshold) continue;
      if (position.y > brick.bottomRight.y + threshold) continue;
      brick.hit(disruptor > 0);
      if (disruptor > 0 && brick.destroyed) {
      } else {
        contacts.add(brick);
      }
      soundboard.play(Sound.wall_hit);

      if (brick.bottomRight.x >= visual.game_pixels.x - 4) {
        logInfo(brick.bottomRight);
        logInfo(visual.game_pixels);
      }
    }
    if (contacts.isEmpty) return;

    // logInfo('contacts: $contacts');

    final width = visual.brick_width.toDouble();
    final height = visual.brick_height.toDouble();

    final speed = velocity.length;
    final speed_y = velocity.y;

    final single = contacts.singleOrNull;
    if (single != null) {
      final x_dist = (position.x - single.topLeft.x).clamp(0.0, width).round();
      final y_dist = (position.y - single.topLeft.y).clamp(0.0, height).round();
      // logInfo('x_dist: $x_dist, y_dist: $y_dist');
      final x_corner = x_dist < threshold || x_dist > width - threshold;
      final y_corner = y_dist < threshold || y_dist > height - threshold;
      // logInfo('x_corner: $x_corner, y_corner: $y_corner');
      final dx = (x_dist - width / 2).sign;
      final dy = (y_dist - height / 2).sign;
      if (x_corner && y_corner) {
        if (single.topLeft.x == 0) {
          velocity.y = -speed_y;
        } else if (single.bottomRight.x >= visual.game_pixels.x - 1) {
          velocity.y = -speed_y;
        } else {
          final nx = -velocity.y;
          final ny = velocity.x;
          velocity.x = nx.abs() * dx.sign;
          velocity.y = ny.abs() * dy.sign;
        }
        // _speed.x = dx;
        // _speed.y = dy;
        // _speed.normalize();
        // _speed.scale(speed);
      } else if (y_corner) {
        velocity.y = -velocity.y;
      } else if (x_corner) {
        if (single.topLeft.x == 0) {
          final nx = -velocity.y;
          final ny = velocity.x;
          velocity.x = nx;
          velocity.y = ny;
        } else if (single.bottomRight.x >= visual.game_pixels.x - 1) {
          final nx = -velocity.y;
          final ny = velocity.x;
          velocity.x = nx;
          velocity.y = ny;
        } else {
          velocity.x = -velocity.x;
        }
      } else {
        throw 'ok?';
      }
    } else if (contacts.length == 2) {
      if (contacts.first.topLeft.x == contacts.last.topLeft.x) {
        if (contacts.first.topLeft.y == contacts.last.topLeft.y) {
          throw 'nono';
        }
        velocity.x = -velocity.x;
      } else if (contacts.first.topLeft.y == contacts.last.topLeft.y) {
        if (contacts.first.topLeft.x == contacts.last.topLeft.x) {
          throw 'nono';
        }
        velocity.y = -velocity.y;
      } else {
        throw 'oh my!';
      }
    } else if (contacts.length == 3) {
      final nx = -velocity.y;
      final ny = velocity.x;
      velocity.x = nx;
      velocity.y = ny;
    } else {
      throw 'oh really?';
    }

    velocity.normalize();
    velocity.scale(speed);
  }

  static final _closest = Vector2.zero();
  static final _bounce_normal = Vector2.zero();
  static final _push = Vector2.zero();

  static const _ball_size = 2.0;

  void _check_bat_hit(double dt) {
    if (_clear_bat) {
      final dist = player.distance_and_closest(position, _closest);
      _clear_bat = dist <= _ball_size;
      if (!_clear_bat) logInfo('bat cleared');

      if (position.x + _ball_size < _player.position.x - _half_bat_width) return;
      if (position.x - _ball_size > _player.position.x + _half_bat_width) return;
      if (position.y + _ball_size < _player.position.y - _half_bat_height) return;
      if (position.y - _ball_size > _player.position.y + _half_bat_height) return;

      do {
        logInfo('MOVE OUT!');
        _player.bounce_vector_or_zero(position, _ball_size, _bounce_normal, _push);
        if (_bounce_normal.isZero()) break;
        _apply_speed(dt);
      } while (!_bounce_normal.isZero());

      // if (position.x < _player.position.x) {
      //   position.x = _player.position.x - _half_bat_width - _ball_size;
      // }
      // if (position.x > _player.position.x) {
      //   position.x = _player.position.x + _half_bat_width + _ball_size;
      // }
      return;
    }

    if (position.x + _ball_size < _player.position.x - _half_bat_width) return;
    if (position.x - _ball_size > _player.position.x + _half_bat_width) return;
    if (position.y + _ball_size < _player.position.y - _half_bat_height) return;
    if (position.y - _ball_size > _player.position.y + _half_bat_height) return;

    _player.bounce_vector_or_zero(position, _ball_size, _bounce_normal, _push);
    if (_bounce_normal.isZero()) return;

    if (_player.catches) {
      state = BallState.caught;
      velocity.setZero();
      caught_offset.setFrom(position);
      caught_offset.sub(_player.position);
      logInfo(caught_offset);
      soundboard.play(Sound.ball_held);
    }

    soundboard.play(Sound.wall_hit);

    logInfo('edge normal: $_bounce_normal');
    logInfo('edge push: $_push');
    logInfo('speed: $velocity');

    if (_bounce_normal.y > 0) {
      logInfo('PUSH');
      final speed = velocity.normalize();
      velocity.add(_bounce_normal);
      velocity.normalize();
      velocity.scale(speed);
      logInfo('push speed: $velocity');
    } else {
      logInfo('BOUNCE');
      bounce(velocity, _bounce_normal);
      velocity.x += _player.x_speed * 0.5;
      velocity.y -= _player.x_speed.abs() * 0.25;
      if (velocity.y > 0) {
        logWarn('why? what?');
        velocity.y = -velocity.y;
      }
      logInfo('bounce speed: $velocity');
    }

    if (!_push.isZero()) {
      velocity.add(_push);
      velocity.add(_push);
      logInfo('after push speed: $velocity');
      logInfo('pos before push: $position');
      // if (_push.x < 0) {
      //   position.x = _player.position.x - _half_bat_width - _ball_size;
      // }
      // if (_push.x > 0) {
      //   position.x = _player.position.x + _half_bat_width + _ball_size;
      // }
      logInfo('pos after push: $position');
    }

    if (velocity.isZero() || velocity.y == 0) {
      logWarn('ZERO (Y) SPEED CORRECTION');
      velocity.y = -_min_speed;
    }

    final dist = player.distance_and_closest(position, _closest);
    _clear_bat = dist <= _ball_size;
  }

  void _check_ball_lost() {
    if (position.y > visual.game_pixels.y - 10 && !_lost) {
      _lost = true;
      soundboard.play(Sound.ball_lost);
    }
    if (position.y > visual.game_pixels.y) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    switch (state) {
      case BallState.gone:
        break;
      case BallState.appearing:
        _render_ball(canvas);
      case BallState.caught:
        _render_ball(canvas);
      case BallState.active:
        _render_ball(canvas);
    }
  }

  void _render_ball(Canvas canvas) {
    sprites.getSpriteById(0).render(canvas, position: position, anchor: Anchor.center, overridePaint: paint);
  }

  // HasGameData

  @override
  load_state(GameData data) {}

  @override
  GameData save_state(GameData data) => throw UnimplementedError();
}

extension BrickExtensions on Brick {
  Vector2 relativePosition(Vector2 position, [Vector2? out]) {
    out ??= Vector2.zero();
    out.setFrom(position);
    out.sub(topLeft);
    return out;
  }

  double pos_and_dist(Vector2 position, Vector2 out) {
    out.x = position.x.clamp(topLeft.x, bottomRight.x);
    out.y = position.y.clamp(topLeft.y, bottomRight.y);
    return position.distanceTo(out);
  }
}
