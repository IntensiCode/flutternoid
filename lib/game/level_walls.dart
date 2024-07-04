import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';

import '../core/common.dart';
import 'game_context.dart';

class Walls extends BodyComponent {
  Walls() {
    renderBody = false;
    debugMode = debug;
    paint.style = PaintingStyle.stroke;
  }

  @override
  Body createBody() => world.createBody(BodyDef(
        userData: this, // To be able to determine object in collision
        position: Vector2.zero(),
        type: BodyType.static,
      ))
        ..createFixture(FixtureDef(
            PolygonShape()
              ..set([
                Vector2(-10, -10),
                Vector2(-10, -3),
                Vector2(visual.game_pixels.x + 10, -3),
                Vector2(visual.game_pixels.x + 10, -10),
              ]),
            friction: 0.0))
        ..createFixture(FixtureDef(
            PolygonShape()
              ..set([
                Vector2(-10, -3),
                Vector2(11, -2.5),
                Vector2(39, -2.5),
                Vector2(39, -3),
              ]),
            friction: 0.0))
        ..createFixture(FixtureDef(
            PolygonShape()
              ..set([
                Vector2(140, -3),
                Vector2(140, -2.5),
                Vector2(168, -2.5),
                Vector2(168, -3),
              ]),
            friction: 0.0));
}

class Wall extends BodyComponent {
  final Vector2 start;
  final Vector2 end;
  final bool sensor;

  Wall({required this.start, required this.end, this.sensor = false});

  @override
  Body createBody() {
    final shape = EdgeShape()..set(start, end);
    final fixtureDef = FixtureDef(shape, friction: 0.0, isSensor: sensor);
    final bodyDef = BodyDef(
      userData: this, // To be able to determine object in collision
      position: Vector2.zero(),
      type: BodyType.static,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
