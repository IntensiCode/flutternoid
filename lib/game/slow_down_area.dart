import 'dart:math';
import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutternoid/game/game_context.dart';
import 'package:flutternoid/util/auto_dispose.dart';
import 'package:flutternoid/util/on_message.dart';

import '../core/common.dart';
import 'ball.dart';
import 'extra_id.dart';
import 'game_configuration.dart';
import 'game_object.dart';

class SlowDownArea extends BodyComponent with AutoDispose, GameObject, ContactCallbacks {
  late final FragmentShader shader;

  late double slow_down_range;
  late double slow_down_top;
  late double slow_down_bottom;

  double _slow_down_time = 0.0;
  double _shade_anim = 0.0;
  double _shade_fade = 0.0;

  SlowDownArea() {
    priority = 5;
    renderBody = debug;
    paint.style = PaintingStyle.stroke;
  }

  // BodyComponent

  @override
  Body createBody() {
    final space = visual.game_pixels;

    slow_down_range = space.y / 3;
    slow_down_top = space.y * 0.6;
    slow_down_bottom = space.y + slow_down_range;

    final shape = PolygonShape()
      ..setAsBox(
        space.x / 2,
        slow_down_range / 2,
        Vector2(space.x / 2, slow_down_range / 2),
        0,
      );
    final fixtureDef = FixtureDef(shape, friction: 0.0, isSensor: true);
    final bodyDef = BodyDef(
      userData: this, // To be able to determine object in collision
      position: Vector2(0, slow_down_top),
      type: BodyType.static,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  final _speeds = <Ball, double>{};

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is Ball) {
      _speeds[other] = _slow_down_time;
    } else {
      contact.isEnabled = false;
    }
  }

  @override
  void endContact(Object other, Contact contact) {
    super.endContact(other, contact);
    if (other is Ball) _speeds.remove(other);
  }

  // Component

  @override
  onLoad() async {
    super.onLoad();
    shader = (await FragmentProgram.fromAsset('assets/shaders/wave.frag')).fragmentShader();
  }

  @override
  void onMount() {
    super.onMount();
    onMessage<SlowDown>((_) => _slow_down_time = configuration.slow_down_time);
  }

  @override
  void update(double dt) {
    if (debug != renderBody) renderBody = debug;
    super.update(dt);

    if (_slow_down_time > 0.0) {
      _slow_down_time -= min(dt, _slow_down_time);
      _shade_anim += dt;
    }

    for (final ball in _speeds.keys) {
      final target_speed = _target_speed(ball);
      if (_slow_down_time > 0.0) {
        if (ball.vy > 0 && ball.speed > target_speed) {
          ball.velocity.normalize();
          ball.velocity.scale(target_speed);
        }
        if (ball.vy < 0 && ball.speed < target_speed) {
          ball.velocity.normalize();
          ball.velocity.scale(target_speed);
        }
      } else if (ball.vy < 0 && ball.speed < target_speed) {
        ball.velocity.normalize();
        ball.velocity.scale(target_speed);
      }
    }

    if (_slow_down_time > 0.0) {
      if (_shade_fade < 1.0) {
        _shade_fade += dt;
        _shade_fade = min(_shade_fade, 1.0);
      }
    } else if (_shade_fade > 0.0) {
      _shade_fade -= dt;
      _shade_fade = max(_shade_fade, 0.0);
    } else {
      _shade_anim = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_shade_fade == 0) return;

    shader.setFloat(0, visual.game_pixels.x);
    shader.setFloat(1, slow_down_range);
    shader.setFloat(2, _shade_anim);
    shader.setFloat(3, _shade_fade);

    final shader_paint = pixelPaint();
    shader_paint.shader = shader;

    if (visual.pixelate) {
      final recorder = PictureRecorder();
      Canvas(recorder).drawRect(Rect.fromLTWH(0, 0, visual.game_pixels.x + 4, slow_down_range), shader_paint);

      final picture = recorder.endRecording();
      final image = picture.toImageSync(visual.game_pixels.x.toInt() + 4, slow_down_range.toInt());
      canvas.drawImage(image, const Offset(-2, 0), paint);
      image.dispose();
      picture.dispose();
    } else {
      canvas.drawRect(Rect.fromLTWH(-2, 0, visual.game_pixels.x + 4, slow_down_range), shader_paint);
    }
  }

  // HasGameData

  @override
  void load_state(GameData data) {}

  @override
  GameData save_state(GameData data) => data;

  // Implementation

  double _target_speed(Ball ball) {
    final factor = (ball.position.y.clamp(slow_down_top, slow_down_bottom) - slow_down_top) / slow_down_range;
    return configuration.min_ball_speed + (configuration.opt_ball_speed - configuration.min_ball_speed) * (1 - factor);
  }
}