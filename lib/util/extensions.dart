import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:flame_texturepacker/flame_texturepacker.dart';
import 'package:kart/kart.dart';

extension ComponentExtension on Component {
  T added<T extends Component>(T it) {
    add(it);
    return it;
  }

  void fadeInDeep({double seconds = 0.2, bool restart = true}) {
    if (this case OpacityProvider it) {
      if (it.opacity == 1 && !restart) return;
      if (it.opacity > 0 && restart) it.opacity = 0;
      add(OpacityEffect.to(1, EffectController(duration: seconds)));
    }
    for (final it in children) {
      it.fadeInDeep(seconds: seconds, restart: restart);
    }
  }

  void fadeOutDeep({double seconds = 0.2, bool restart = false, bool and_remove = true}) {
    if (this case OpacityProvider it) {
      if (it.opacity == 0 && !restart) return;
      if (it.opacity < 1 && restart) it.opacity = 1;
      add(OpacityEffect.to(0, EffectController(duration: seconds)));
    }
    for (final it in children) {
      it.fadeOutDeep(seconds: seconds, restart: restart, and_remove: false);
    }
    if (and_remove) add(RemoveEffect(delay: seconds));
  }

  void runScript(List<(int, void Function())> script) {
    for (final step in script) {
      _doAt(step.$1, () {
        if (!isMounted) return;
        step.$2();
      });
    }
  }

  void _doAt(int millis, Function() what) {
    Future.delayed(Duration(milliseconds: millis)).then((_) => what());
  }
}

extension ComponentSetExtensions on ComponentSet {
  operator -(Component component) => where((it) => it != component);
}

extension DynamicListExtensions on List<dynamic> {
  List<T> mapToType<T>() => map((it) => it as T).toList();

  void rotateLeft() => add(removeAt(0));

  void rotateRight() => insert(0, removeLast());
}

extension IterableExtensions<T> on Iterable<T> {
  List<R> mapList<R>(R Function(T) f) => map(f).toList();
}

extension ListExtensions<T> on List<T> {
  void fill(T it) => fillRange(0, length, it);

  List<R> mapList<R>(R Function(T) f) => map(f).toList();

  T? nextAfter(T? it) {
    if (it == null) return firstOrNull();
    final index = indexOf(it);
    if (index == -1) return null;
    return this[(index + 1) % length];
  }

  void removeAll(Iterable<T> other) {
    for (final it in other) {
      remove(it);
    }
  }

  T? removeLastOrNull() {
    if (isEmpty) return null;
    return removeLast();
  }

  List<T> operator -(List<T> other) => whereNot((it) => other.contains(it)).toList();
}

extension RandomExtensions on Random {
  double nextDoubleLimit(double limit) => nextDouble() * limit;

  double nextDoublePM(double limit) => (nextDouble() - nextDouble()) * limit;
}

extension FragmentShaderExtensions on FragmentShader {
  setVec4(int index, Color color) {
    final r = color.red / 255 * color.opacity;
    final g = color.green / 255 * color.opacity;
    final b = color.blue / 255 * color.opacity;
    setFloat(index + 0, r);
    setFloat(index + 1, g);
    setFloat(index + 2, b);
    setFloat(index + 3, color.opacity);
  }
}

extension IntExtensions on int {
  forEach(void Function(int) f) {
    for (var i = 0; i < this; i++) {
      f(i);
    }
  }
}

extension PaintExtensions on Paint {
  set opacity(double progress) {
    color = Color.fromARGB((255 * progress).toInt(), 255, 255, 255);
  }
}

extension StringExtensions on String {
  List<String> lines() => split('\n');
}

extension Vector3Extension on Vector3 {
  void lerp(Vector3 other, double t) {
    x = x + (other.x - x) * t;
    y = y + (other.y - y) * t;
    z = z + (other.z - z) * t;
  }
}

extension SpriteSheetExtensions on SpriteSheet {
  Sprite by_row(int row, double progress) => getSprite(row, ((columns - 1) * progress).toInt());

  Sprite by_progress(double progress) => getSpriteById(((columns - 1) * progress).toInt());
}

extension TexturePackerAtlasExtensions on TexturePackerAtlas {
  Sprite image(String name) {
    final sprite = findSpriteByName(name.replaceFirst('.png', ''));
    if (sprite == null) throw 'unknown atlas id: $name';
    return sprite;
  }

  SpriteComponent spriteXY(String name, double x, double y, Anchor anchor) {
    final sprite = findSpriteByName(name.replaceFirst('.png', ''));
    if (sprite == null) throw 'unknown atlas id: $name';
    return SpriteComponent(sprite: sprite, position: Vector2(x, y), anchor: anchor);
  }

  TexturePackerSpriteSheet sheetIWH(String name, int width, int height, {int spacing = 0}) {
    final sprite = findSpriteByName(name.replaceFirst('.png', ''));
    if (sprite == null) throw 'unknown atlas id: $name';
    return TexturePackerSpriteSheet.wh(sprite, width, height, spacing: spacing);
  }

  TexturePackerSpriteSheet sheetI(String name, int columns, int rows) {
    final sprite = findSpriteByName(name.replaceFirst('.png', ''));
    if (sprite == null) throw 'unknown atlas id: $name';
    return TexturePackerSpriteSheet.cr(sprite, columns, rows);
  }
}

class TexturePackerSpriteSheet implements SpriteSheet {
  TexturePackerSpriteSheet.wh(this.sprite, this.tile_width, this.tile_height, {required int spacing})
      : columns = (sprite.src.width / (tile_width + spacing)).round(),
        rows = (sprite.src.height / (tile_height + spacing)).round(),
        _spacing = spacing;

  TexturePackerSpriteSheet.cr(this.sprite, this.columns, this.rows)
      : tile_width = sprite.src.width ~/ columns,
        tile_height = sprite.src.height ~/ rows,
        _spacing = 0;

  final Sprite sprite;
  final int tile_width;
  final int tile_height;
  final int _spacing;

  late final tile_size = Vector2(tile_width.toDouble(), tile_height.toDouble());

  @override
  final int columns;

  @override
  final int rows;

  @override
  Image get image => sprite.image;

  @override
  double get spacing => _spacing.toDouble();

  final _sprites = <int, Sprite>{};

  @override
  Sprite getSpriteById(int id) {
    if (!_sprites.containsKey(id)) {
      final src = sprite.src;
      final x = id % columns;
      final y = id ~/ columns;
      final xx = src.left + x * (tile_width + _spacing);
      final yy = src.top + y * (tile_height + _spacing);
      return Sprite(sprite.image, srcPosition: Vector2(xx, yy), srcSize: tile_size);
    }
    return _sprites[id]!;
  }

  @override
  Sprite getSprite(int row, int column) => getSpriteById(row * columns + column);

  @override
  SpriteAnimation createAnimation({
    required int row,
    required double stepTime,
    bool loop = true,
    int from = 0,
    int? to,
  }) {
    final end = to ?? (columns - 1);
    final sprites = [for (int i = from; i <= end; i++) getSpriteById(row * columns + i)];
    return SpriteAnimation.spriteList(sprites, stepTime: stepTime)..loop = loop;
  }

  @override
  SpriteAnimation createAnimationWithVariableStepTimes({
    required int row,
    required List<double> stepTimes,
    bool loop = true,
    int from = 0,
    int? to,
  }) {
    throw UnimplementedError();
  }

  @override
  SpriteAnimationFrameData createFrameData(int row, int column, {required double stepTime}) {
    throw UnimplementedError();
  }

  @override
  SpriteAnimationFrameData createFrameDataFromId(int spriteId, {required double stepTime}) {
    throw UnimplementedError();
  }

  @override
  double get margin => throw UnimplementedError();

  @override
  Vector2 get srcSize => throw UnimplementedError();
}
