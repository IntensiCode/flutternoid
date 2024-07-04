import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../core/messaging.dart';
import '../core/soundboard.dart';
import '../input/keys.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/on_message.dart';
import 'ball.dart';
import 'extra_id.dart';
import 'game_context.dart';
import 'game_object.dart';
import 'laser_weapon.dart';

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

enum PlayerMode {
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

class Player extends BodyComponent with AutoDispose, ContactCallbacks, GameObject {
  final LaserWeapon laser;

  late final Keys _keys;
  late final SpriteSheet sprites;
  late final SpriteSheet explosion;

  late final SpriteAnimationComponent left_thruster;
  late final SpriteAnimationComponent right_thruster;

  final _acceleration = 1200.0;
  final _deceleration = 1500.0;
  final _max_speed = 300.0;

  var state = PlayerState.entering;
  var state_progress = 0.0;
  var mode = PlayerMode.normal1;
  double bat_height = 6;

  double expanded = 0;
  int expand_level = 0;
  double mode_time = 0;
  double _mode_change = 0;
  late PlayerMode _mode_origin;

  double get x_speed => body.linearVelocity.x;

  set x_speed(double value) => body.linearVelocity.x = value;

  Player(this.laser);

  bool get in_normal_mode => mode.index % 3 == 0;

  bool get in_catcher_mode => mode.index % 3 == 1;

  bool get in_laser_mode => mode.index % 3 == 2;

  bool get hard_edge => (mode.index % 3) == 2;

  double get bat_edge => (mode.index % 3) == 2 ? 2 : 4;

  double get bat_width => 26 + mode.index ~/ 3 * 4 - 2;

  double distance_and_closest(Vector2 it, [Vector2? out_closest]) {
    out_closest ??= Vector2.zero();
    out_closest.x = it.x.clamp(position.x - bat_width / 2, position.x + bat_width / 2);
    out_closest.y = it.y.clamp(position.y - bat_height / 2, position.y + bat_height / 2);
    return it.distanceTo(out_closest);
  }

  // BodyComponent

  @override
  Body createBody() => world.createBody(BodyDef(
        gravityOverride: Vector2.zero(),
        userData: this,
        position: Vector2(visual.game_pixels.x / 2, visual.game_pixels.y * 0.9),
        type: BodyType.static,
      ));

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is Ball && !in_catcher_mode) {
      other.body.applyLinearImpulse(Vector2(player.x_speed, 0));
    }
  }

  // Component

  @override
  onLoad() async {
    super.onLoad();

    priority = 1;

    paint = pixelPaint();
    paint.style = PaintingStyle.stroke;

    _keys = keys;
    sprites = await sheetIWH('game_bat.png', 36, 8);
    explosion = await sheetIWH('game_explosion.png', 32, 32);
    final thrust = await sheetIWH('game_thrust.png', 7, 6);
    add(left_thruster = SpriteAnimationComponent(
      animation: thrust.createAnimation(row: 0, stepTime: 0.05),
      anchor: Anchor.topRight,
      position: Vector2(-bat_width / 2, -bat_height / 2 - 1),
    ));
    add(right_thruster = SpriteAnimationComponent(
      animation: thrust.createAnimation(row: 1, stepTime: 0.05),
      position: Vector2(bat_width / 2, -bat_height / 2 - 1),
    ));
    left_thruster.opacity = _thrust_left > 0 ? 1.0 : 0.0;
    right_thruster.opacity = _thrust_right > 0 ? 1.0 : 0.0;

    body.setTransform(Vector2(visual.game_pixels.x / 2, visual.game_pixels.y * 0.9), 0);
    _update_body_fixture();
    renderBody = debug;
  }

  _update_body_fixture() {
    if (body.fixtures.isNotEmpty) {
      body.destroyFixture(body.fixtures.single);
    }
    body.createFixture(_updated_fixture());
  }

  FixtureDef _updated_fixture() => FixtureDef(
        PolygonShape()..set(_updated_shape()),
        restitution: 0.0,
        density: 1000,
      );

  List<Vector2> _updated_shape() => [
        Vector2(-bat_width / 2 - 1, -1),
        Vector2(-bat_width / 2 + bat_edge - 1, -bat_height / 2),
        Vector2(bat_width / 2 - bat_edge + 1, -bat_height / 2),
        Vector2(bat_width / 2 + 1, -1),
        Vector2(bat_width / 2 - bat_edge + 3, bat_height / 2),
        Vector2(-bat_width / 2 + bat_edge - 3, bat_height / 2),
        Vector2(-bat_width / 2 - 1, -1),
      ];

  @override
  void onMount() {
    super.onMount();
    onMessage<Catcher>((_) => _on_catcher());
    onMessage<Expander>((_) => _on_expander());
    onMessage<Laser>((_) => _on_laser());
  }

  void _on_catcher() {
    if (in_catcher_mode) return;

    _mode_origin = mode;
    _mode_change = 1.0;
    mode = PlayerMode.values[expand_level * 3 + PlayerMode.catcher1.index];
    mode_time += configuration.mode_time;

    _update_body_fixture();
  }

  void _on_laser() {
    if (in_laser_mode) return;

    _mode_origin = mode;
    _mode_change = 1.0;
    mode = PlayerMode.values[expand_level * 3 + PlayerMode.laser1.index];
    mode_time += configuration.mode_time;

    body.destroyFixture(body.fixtures.single);
    body.createFixture(FixtureDef(PolygonShape()..set(_updated_shape()), restitution: 0.0, density: 1000));
  }

  void _on_mode_reset() {
    if (in_normal_mode) return;

    _mode_origin = mode;
    _mode_change = 1.0;
    mode = PlayerMode.values[expand_level * 3 + PlayerMode.normal1.index];

    body.destroyFixture(body.fixtures.single);
    body.createFixture(FixtureDef(PolygonShape()..set(_updated_shape()), restitution: 0.0, density: 1000));
  }

  void _on_expander() {
    if (expand_level >= 2) return;
    expand_level++;
    expanded = configuration.expand_time;
    mode = PlayerMode.values[expand_level * 3 + (mode.index % 3)];
    soundboard.play(Sound.bat_expand);

    body.destroyFixture(body.fixtures.single);
    body.createFixture(FixtureDef(PolygonShape()..set(_updated_shape()), restitution: 0.0, density: 1000));
  }

  @override
  void update(double dt) {
    if (debug != renderBody) renderBody = debug;
    super.update(dt);
    switch (state) {
      case PlayerState.gone:
        break;
      case PlayerState.entering:
        _on_entering(dt);
      case PlayerState.leaving:
        _on_leaving(dt);
      case PlayerState.exploding:
        _on_exploding(dt);
      case PlayerState.playing:
        _on_playing_move(dt);
        _on_playing_fire(dt);
        _on_expansion(dt);
        _on_mode_change(dt);
        _on_thrusters(dt);
    }
  }

  void _on_thrusters(double dt) {
    if (_thrust_left > 0) _thrust_left -= min(_thrust_left, dt);
    if (_thrust_right > 0) _thrust_right -= min(_thrust_right, dt);
    left_thruster.opacity = _thrust_left > 0 ? 1.0 : 0.0;
    right_thruster.opacity = _thrust_right > 0 ? 1.0 : 0.0;
  }

  void _on_mode_change(double dt) {
    if (mode_time > 0) {
      mode_time -= min(mode_time, dt);
      if (mode_time <= 0) _on_mode_reset();
    }
    if (_mode_change > 0) {
      _mode_change -= min(_mode_change, dt * 3);
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

  final _update_pos = Vector2.zero();

  var _thrust_left = 0.0;
  var _thrust_right = 0.0;

  void _on_playing_move(double dt) {
    if (_keys.check(GameKey.left)) {
      if (x_speed >= 0) _thrust_right = 0.2;
      if (x_speed > 0) x_speed -= _deceleration * dt;
      x_speed -= _acceleration * dt;
    } else if (_keys.check(GameKey.right)) {
      if (x_speed <= 0) _thrust_left = 0.2;
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

    _update_pos.setFrom(body.transform.p);
    _update_pos.x += x_speed * dt;

    final x_stop = bat_width / 2;
    if (_update_pos.x < x_stop) {
      _update_pos.x = x_stop;
    }
    if (_update_pos.x > visual.game_pixels.x - x_stop) {
      _update_pos.x = visual.game_pixels.x - x_stop;
    }

    body.setTransform(_update_pos, 0);
  }

  final _laser_pos = Vector2.zero();

  void _on_playing_fire(double dt) {
    if (_keys.check_and_consume(GameKey.fire1)) {
      final caught = balls.where((it) => it.state == BallState.caught).firstOrNull;
      caught?.push(x_speed * 0.5, -_max_speed * 0.5);
      if (caught == null && in_laser_mode) {
        _laser_pos.setFrom(position);
        _laser_pos.x -= bat_width / 4;
        laser.spawn(_laser_pos);

        _laser_pos.setFrom(position);
        _laser_pos.x += bat_width / 4;
        laser.spawn(_laser_pos);

        soundboard.play(Sound.laser_shot);
      }
    }
  }

  void _on_expansion(double dt) {
    if (expanded <= 0) return;

    expanded -= min(expanded, dt);
    if (expanded > 0) return;

    if (expand_level > 0) {
      expand_level--;
      if (expand_level > 0) expanded = configuration.expand_time;
      mode = PlayerMode.values[expand_level * 3 + (mode.index % 3)];
    }
    logInfo('expanded=$expanded, expand_level=$expand_level, bat_mode=$mode');
    soundboard.play(Sound.bat_expand);
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

  final _mode_paint = pixelPaint();

  void _render_bat(Canvas canvas) {
    if (_mode_change > 0) {
      final from = sprites.getSpriteById(_mode_origin.index);
      final to = sprites.getSpriteById(mode.index);
      _mode_paint.opacity = _mode_change;
      from.render(canvas, overridePaint: _mode_paint, anchor: Anchor.center);
      _mode_paint.opacity = 1 - _mode_change;
      to.render(canvas, overridePaint: _mode_paint, anchor: Anchor.center);
    } else {
      sprites.getSpriteById(mode.index).render(canvas, overridePaint: paint, anchor: Anchor.center);
    }
  }

  // HasGameData

  @override
  void load_state(GameData data) {}

  @override
  GameData save_state(GameData data) => throw UnimplementedError();
}
