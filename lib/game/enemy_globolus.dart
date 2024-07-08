import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../core/functions.dart';
import '../core/random.dart';
import '../util/extensions.dart';
import 'enemy.dart';

class EnemyGlobolus extends Enemy {
  EnemyGlobolus() : super(radius: 8);

  @override
  void postSolve(Object other, Contact contact, ContactImpulse impulse) {
    super.postSolve(other, contact, impulse);
    body.linearVelocity.rotate(rng.nextDoublePM(pi / 8));
  }

  @override
  onLoad() async {
    super.onLoad();
    animation = await sheetIWH('enemy_globolus.png', 16, 16);
  }
}
