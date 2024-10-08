import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Particle;
import 'package:flame_texturepacker/flame_texturepacker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool debug = kDebugMode && !kIsWeb;
bool dev = kDebugMode;

const tps = kIsWeb ? 60 : 120;

const double gameWidth = 320;
const double gameHeight = 200;
final Vector2 gameSize = Vector2(gameWidth, gameHeight);

const xCenter = gameWidth / 2;
const yCenter = gameHeight / 2;
const fontScale = gameHeight / 500;
const lineHeight = 24 * fontScale;
const debugHeight = 12 * fontScale;

late TexturePackerAtlas atlas;
late Game game;
late Forge2DWorld world;
late Images images;

// to avoid importing materials elsewhere (which causes clashes sometimes), some color values right here:
const transparent = Colors.transparent;
const shadow = Color(0x80000000);
const black = Colors.black;
const white = Colors.white;
const red = Colors.red;
const orange = Colors.orange;
const yellow = Colors.yellow;
const blue = Colors.blue;

Paint pixelPaint() => Paint()
  ..isAntiAlias = false
  ..filterQuality = FilterQuality.none;

ParticleSystemComponent Particles(Particle root) => ParticleSystemComponent(particle: root);

mixin Message {}

class MouseWheel with Message {
  final double direction;

  MouseWheel(this.direction);
}

TODO(String message) => throw UnimplementedError(message);
