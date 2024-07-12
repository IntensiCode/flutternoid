import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutternoid/core/common.dart';

class Wall extends BodyComponent {
  final List<Vector2> hull;

  Wall({required this.hull}) {
    paint.style = PaintingStyle.stroke;
  }

  @override
  Body createBody() {
    final shape = PolygonShape()..set(hull);
    final fixtureDef = FixtureDef(shape, friction: 0.0);
    final bodyDef = BodyDef(
      userData: this, // To be able to determine object in collision
      position: Vector2.zero(),
      type: BodyType.static,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (renderBody != debug) renderBody = debug;
  }
}
