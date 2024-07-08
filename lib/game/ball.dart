import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart' hide World;
import 'package:flame/sprite.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/cupertino.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../core/messaging.dart';
import '../core/random.dart';
import '../core/soundboard.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/on_message.dart';
import 'brick.dart';
import 'game_configuration.dart';
import 'game_context.dart';
import 'game_messages.dart';
import 'game_object.dart';
import 'player.dart';
import 'wall.dart';

enum BallState {
  gone,
  appearing,
  caught,
  active,
  pushed,
  exploding,
}

class Ball extends BodyComponent with AutoDispose, GameObject, ContactCallbacks {
  late final Player _player;
  late final double _half_bat_height;
  late final SpriteSheet sprites;
  late final FragmentShader shader;

  Ball? _spawn_origin;
  Vector2? _spawn_velocity;

  final _caught_offset = Vector2(0, -3);
  final _update_position = Vector2.zero();

  var _state = BallState.appearing;

  BallState get state => _state;

  set state(BallState value) {
    logInfo('new ball state: $value');
    _state = value;
  }

  var state_progress = 0.0;
  var disruptor = 0.0;
  var _jiggle = 0.0;

  bool _lost = false;

  Vector2 get velocity => body.linearVelocity;

  double get vy => body.linearVelocity.y;

  double get speed => body.linearVelocity.length;

  Ball();

  Ball.spawned(Ball origin, Vector2 velocity) {
    _spawn_origin = origin;
    _spawn_velocity = velocity;
  }

  final _push_delta = Vector2.zero();

  push(double dx, double dy) {
    state = BallState.pushed;

    body.linearVelocity.setZero();

    _push_delta.setValues(dx, dy);
    _update_position.setFrom(position);

    if (_jiggle > 0) {
      final factor = max(0.0, _jiggle - 0.25);
      _push_delta.rotate(rng.nextDoublePM(factor));
    }
  }

  caught() {
    state = BallState.caught;
    velocity.setZero();
    _caught_offset.setFrom(position);
    _caught_offset.sub(_player.position);
  }

  jiggle(double force) => _jiggle = force;

  explode() {
    velocity.setZero();

    renderBody = false;
    debugMode = false;
    paint.style = PaintingStyle.stroke;

    state = BallState.exploding;
    state_progress = 0.0;
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
      fixedRotation: true,
      gravityOverride: Vector2.zero(),
      position: Vector2(visual.game_pixels.x / 2, visual.game_pixels.y * 0.8),
      userData: this,
      type: BodyType.dynamic,
    );

    return world.createBody(body)..createFixture(shape);
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is Ball && other.state != BallState.active || this.state != BallState.active) {
      contact.isEnabled = false;
    } else if (other is Brick) {
      other.hit(disruptor > 0);
      if (disruptor > 0 && other.destroyed) contact.isEnabled = false;
      soundboard.trigger(Sound.wall_hit);
    } else if (other is Player && other.in_catcher_mode) {
      contact.isEnabled = false;
    } else if (other is Player || other is Wall) {
      soundboard.trigger(Sound.wall_hit);
    }
  }

  @override
  void postSolve(Object other, Contact contact, ContactImpulse impulse) {
    super.postSolve(other, contact, impulse);
    if (other is Brick) {
      if (body.linearVelocity.x.abs() < configuration.min_ball_x_speed_after_brick_hit) {
        body.linearVelocity.x += body.linearVelocity.x.sign;
      }
    }
  }

  // Component

  @override
  onLoad() async {
    super.onLoad();

    shader = (await FragmentProgram.fromAsset('assets/shaders/explosion.frag')).fragmentShader();

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
    onMessage<TriggerPlasmaBlasts>((_) => _on_trigger_plasma_blast());
  }

  void _on_trigger_plasma_blast() {
    if (state != BallState.active) return;
    sendMessage(TriggerPlasmaBlast(position));
    body.linearVelocity.x = rng.nextDoublePM(1);
    body.linearVelocity.y = -1;
    body.linearVelocity.scale(configuration.opt_ball_speed);
    disruptor += configuration.plasma_disruptor;
  }

  @override
  void update(double dt) {
    if (debug != renderBody) renderBody = debug;
    if (state != BallState.caught) _jiggle = 0.0;
    super.update(dt);
    switch (state) {
      case BallState.gone:
        break;
      case BallState.appearing:
        _on_appearing(dt);
      case BallState.caught:
        _on_caught(dt);
      case BallState.pushed:
        _on_pushed(dt);
      case BallState.active:
        _on_active(dt);
      case BallState.exploding:
        state_progress += dt;
        if (state_progress >= 1.0) {
          state = BallState.gone;
          logInfo('ball exploded');
          removeFromParent();
        }
    }
  }

  void _on_pushed(double dt) {
    if (state == BallState.pushed && position.y < _player.position.y - _player.bat_height) {
      body.linearVelocity.setFrom(_push_delta);
      body.applyLinearImpulse(_push_delta, wake: true);
      state = BallState.active;
    }

    _update_position.setFrom(_push_delta);
    _update_position.scale(dt);
    _update_position.add(position);

    body.setTransform(_update_position, 0);
  }

  void _on_appearing(double dt) {
    _update_position.setFrom(_player.position);
    _update_position.y -= _half_bat_height;
    body.setTransform(_update_position, 0);

    state_progress += dt * 4;
    if (state_progress >= 1.0) {
      paint.opacity = 1;
      state_progress = 0.0;
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

    if (body.linearVelocity.length > configuration.max_ball_speed) {
      body.linearVelocity.normalize();
      body.linearVelocity.scale(configuration.max_ball_speed);
    }
    if (body.linearVelocity.y.abs() < configuration.min_ball_speed) {
      final speed = body.linearVelocity.length;
      body.linearVelocity.y = configuration.min_ball_speed * body.linearVelocity.y.sign;
      body.linearVelocity.normalize();
      body.linearVelocity.scale(speed);
    }
    if (body.linearVelocity.y.round() == 0) {
      final speed = body.linearVelocity.normalize();
      body.linearVelocity.y = -configuration.min_ball_speed;
      body.linearVelocity.normalize();
      body.linearVelocity.scale(speed);
    }
  }

  void _check_ball_lost() {
    if (position.y > visual.game_pixels.y - 10 && !_lost) {
      _lost = true;
      soundboard.trigger(Sound.ball_lost);
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
      case BallState.pushed:
      case BallState.active:
        _render_ball(canvas);
      case BallState.exploding:
        _render_exploding(canvas);
    }
  }

  void _render_exploding(Canvas canvas) {
    const size = 64.0;
    shader.setFloat(0, size);
    shader.setFloat(1, size);
    shader.setFloat(2, state_progress);

    final shaded = pixelPaint();
    shaded.shader = shader;

    if (visual.pixelate) {
      final recorder = PictureRecorder();
      Canvas(recorder).drawCircle(Offset.zero, 64, shaded);

      final picture = recorder.endRecording();
      final image = picture.toImageSync(size.toInt(), size.toInt());
      canvas.translate(-size / 2, -size / 2);
      canvas.drawImage(image, Offset.zero, paint);
      image.dispose();
      picture.dispose();
    } else {
      canvas.translate(-size / 2, -size / 2);
      canvas.drawCircle(Offset.zero, size, shaded);
    }
  }

  final _render_pos = Vector2.zero();

  void _render_ball(Canvas canvas) {
    if (_jiggle > 0) {
      final factor = Curves.easeIn.transform(_jiggle) * 2.5;
      _render_pos.x = rng.nextDoublePM(factor);
      _render_pos.y = rng.nextDoublePM(factor);
      sprites.getSpriteById(0).render(canvas, position: _render_pos, anchor: Anchor.center, overridePaint: paint);
    } else {
      sprites.getSpriteById(0).render(canvas, anchor: Anchor.center, overridePaint: paint);
    }
  }

  // HasGameData

  @override
  load_state(GameData data) {}

  @override
  GameData save_state(GameData data) => throw UnimplementedError();
}
