import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart' hide World;
import 'package:flame/sprite.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/cupertino.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../core/soundboard.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/on_message.dart';
import 'brick.dart';
import 'extra_id.dart';
import 'game_context.dart';
import 'game_object.dart';
import 'player.dart';

enum BallState {
  gone,
  appearing,
  caught,
  active,
}

class Ball extends BodyComponent with AutoDispose, GameObject, ContactCallbacks {
  late final Player _player;
  late final double _half_bat_height;
  late final SpriteSheet sprites;

  Ball? _spawn_origin;
  Vector2? _spawn_velocity;

  final _caught_offset = Vector2(0, -3);
  final _update_position = Vector2.zero();

  final max_speed = 200.0;
  final opt_speed = 150.0;
  final min_speed = 25.0;

  var state = BallState.appearing;
  var state_progress = 0.0;
  var disruptor = 0.0;

  bool _lost = false;

  Vector2 get velocity => body.linearVelocity;

  double get vy => body.linearVelocity.y;

  double get speed => body.linearVelocity.length;

  Ball();

  Ball.spawned(Ball origin, Vector2 velocity) {
    _spawn_origin = origin;
    _spawn_velocity = velocity;
  }

  push(double dx, double dy) {
    state = BallState.active;
    body.linearVelocity.setValues(dx, dy);
  }

  // BodyComponent

  @override
  Body createBody() {
    renderBody = debug;
    paint.style = PaintingStyle.stroke;

    final shape = FixtureDef(
      CircleShape()..radius = 2,
      restitution: 1.0,
    );

    final body = BodyDef(
      bullet: true,
      gravityOverride: Vector2.zero(),
      userData: this,
      type: BodyType.dynamic,
    );

    return world.createBody(body)..createFixture(shape);
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is Brick) {
      other.hit(disruptor > 0);
      if (disruptor > 0 && other.destroyed) contact.isEnabled = false;
    }
    if (other is Player && state == BallState.active) {
      if (other.in_catcher_mode) {
        state = BallState.caught;
        velocity.setZero();
        _caught_offset.setFrom(position);
        _caught_offset.sub(other.position);
        contact.isEnabled = false;
      }
    }
    soundboard.play(Sound.wall_hit);
  }

  // Component

  @override
  onLoad() async {
    super.onLoad();

    priority = 2;

    paint = pixelPaint();

    _player = player;
    _half_bat_height = _player.bat_height / 2.0;

    sprites = await sheetIWH('game_ball.png', 4, 4, spacing: 2);

    if (_spawn_origin case Ball origin) {
      body.setTransform(origin.body.transform.p, 0);
      body.linearVelocity.setFrom(_spawn_velocity!);
      state = origin.state;
    }
  }

  @override
  void onMount() {
    super.onMount();
    onMessage<Disruptor>((it) => disruptor = configuration.disruptor_time);
  }

  @override
  void update(double dt) {
    if (debug != renderBody) renderBody = debug;
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
    _update_position.setFrom(_player.position);
    _update_position.y -= _half_bat_height;
    body.setTransform(_update_position, 0);

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
    if (_caught_offset.x < 0) _caught_offset.x += 20 * dt;
    if (_caught_offset.x > 0) _caught_offset.x -= 20 * dt;
    if (_caught_offset.y < -_half_bat_height) _caught_offset.y += 10 * dt;
    if (_caught_offset.y > -_half_bat_height) _caught_offset.y -= 10 * dt;
    _update_position.setFrom(_player.position);
    _update_position.add(_caught_offset);
    body.setTransform(_update_position, 0);
  }

  void _on_active(double dt) {
    if (disruptor > 0) disruptor -= min(disruptor, dt);
    _check_ball_lost();

    if (body.linearVelocity.length > max_speed) {
      body.linearVelocity.normalize();
      body.linearVelocity.scale(max_speed);
    }
    if (body.linearVelocity.y.abs() < min_speed) {
      final speed = body.linearVelocity.length;
      body.linearVelocity.y = min_speed * body.linearVelocity.y.sign;
      body.linearVelocity.normalize();
      body.linearVelocity.scale(speed);
    }
    if (body.linearVelocity.y.round() == 0) {
      final speed = body.linearVelocity.normalize();
      body.linearVelocity.y = -min_speed;
      body.linearVelocity.normalize();
      body.linearVelocity.scale(speed);
    }
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
    sprites.getSpriteById(0).render(canvas, anchor: Anchor.center, overridePaint: paint);
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
