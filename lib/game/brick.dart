import 'package:flame/components.dart';

import 'brick_id.dart';

export 'brick_id.dart';

class Brick {
  final BrickId id;
  final Vector2 topLeft;
  final Vector2 bottomRight;

  late final center = (topLeft + bottomRight) / 2;

  Brick(this.id, this.topLeft, this.bottomRight);

  int _hits = 0;
  bool _destroyed = false;

  int get hits => _hits;

  bool get destroyed => _destroyed;

  void hit() {
    if (_hits < id.strength) {
      // _hits++;
      // hit_highlight += 0.1;
      _hits = id.strength;
      _destroyed = true;
    } else {
      _destroyed = true;
    }
  }

  double hit_highlight = 0;
  double destroy_progress = 0.0;

  bool get gone => destroyed && destroy_progress >= 1.0;

  @override
  String toString() {
    final x = topLeft.x / 12;
    final y = topLeft.y / 6;
    return 'Brick(id: $id, x: $x, y: $y, hits: $hits, destroyed: $destroyed)';
  }
}
