import 'package:flame/components.dart';
import 'package:flutternoid/game/ball.dart';
import 'package:flutternoid/game/brick.dart';
import 'package:flutternoid/game/player.dart';
import 'package:flutternoid/game/player_extensions.dart';
import 'package:flutternoid/util/geom.dart';
import 'package:test/test.dart';

void main() {
  group('bounce', () {
    test('bounces straight back', () {
      final actual = bounce(Vector2(0, 100), Vector2(0, -1));
      expect(actual, equals(Vector2(0, -100)));
    });

    test('bounces 90 degrees', () {
      final actual = bounce(Vector2(100, 100), Vector2(0, -1));
      expect(actual..round(), equals(Vector2(100, -100)));
    });

    test('bounces back angled', () {
      final actual = bounce(Vector2(100, 100), Vector2(-1, -1));
      expect(actual..round(), equals(Vector2(-100, -100)));
    });

    test('bounces back angled', () {
      final actual = bounce(Vector2(100, 10), Vector2(0, -1));
      expect(actual..round(), equals(Vector2(100, -10)));
    });

    test('bounces or pushes?', () {
      final actual = bounce(Vector2(0, 1), Vector2(-1, 1));
      expect(actual..round(), equals(Vector2(-1, 1)));
    });
  });

  test('finds relative brick position', () {
    // given
    final position = Vector2(82, 82);
    final brick = Brick(BrickId.blue1, Vector2(80, 80), Vector2(92, 86));

    // when
    final actual = brick.relativePosition(position);

    // then
    expect(actual, equals(Vector2(2, 2)));
  });

  test('finds relative player position', () {
    // given
    final position = Vector2(100, 100);
    final player = Player()..position = Vector2(100, 100);

    // when
    final actual = player.relative_position(position);

    // then
    expect(actual, equals(Vector2(12, 3)));
  });

  test('finds normalized relative player position', () {
    // given
    final position = Vector2(100, 100);
    final player = Player()..position = Vector2(100, 100);

    // when
    final normalized = Vector2.zero();
    player.relative_position(position, normalized: normalized);

    // then
    expect(normalized, equals(Vector2(0.5, 0.5)));
  });

  test('finds relative player corner position', () {
    // given
    final position = Vector2(87, 97);
    final player = Player()..position = Vector2(100, 100);

    // when
    final actual = player.relative_position(position);

    // then
    expect(actual, equals(Vector2(-1, 0)));
  });

  test('finds normalized relative player corner position', () {
    // given
    final position = Vector2(112, 100);
    final player = Player()..position = Vector2(100, 100);

    // when
    final normalized = Vector2.zero();
    player.relative_position(position, normalized: normalized);

    // then
    expect(normalized, equals(Vector2(1.0, 0.5)));
  });

  test('finds closest position and distance to player', () {
    // given
    final position = Vector2(100, 95);
    final player = Player()..position = Vector2(100, 100);

    // when
    final closest = Vector2.zero();
    final distance = player.distance_and_closest(position, closest);

    // then
    expect(distance, equals(2));
    expect(closest, equals(Vector2(100, 97)));
  });

  test('ball does not touch bat edge', () {
    // when
    final actual = circle_touches_line(Vector2(100, 100), 2, 100, 103, 103, 100);

    // then
    expect(actual, isFalse);
  });

  test('ball touches bat edge', () {
    // when
    final actual = circle_touches_line(Vector2(101, 101), 2, 100, 103, 103, 100);

    // then
    expect(actual, isTrue);
  });

  test('ball does not touch bat edge', () {
    // when
    final actual = circle_touches_line(Vector2(100, 100), 2, 100, 103, 103, 100);

    // then
    expect(actual, isFalse);
  });

  test('ball touches bat top', () {
    // when
    final actual = circle_touches_line(Vector2(105, 95), 2, 100, 97, 110, 97);

    // then
    expect(actual, isTrue);
  });

  test('ball does not touch bat top', () {
    // when
    final actual = circle_touches_line(Vector2(105, 94.5), 2, 100, 97, 110, 97);

    // then
    expect(actual, isFalse);
  });
}
