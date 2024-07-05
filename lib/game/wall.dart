import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutternoid/core/common.dart';

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

  @override
  void update(double dt) {
    super.update(dt);
    if (renderBody != debug) renderBody = debug;
  }
}
