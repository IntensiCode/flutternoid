import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import 'game_context.dart';

class LaserWeapon extends Component with AutoDispose {
  late final SpriteSheet sprites;

  spawn(Vector2 top_center) {
    final it = _pool.removeLastOrNull() ?? LaserShot(_recycle);
    it.reset(sprites, Vector2(top_center.x, top_center.y - 5.0));
    add(it);
  }

  // Component

  @override
  onLoad() async {
    priority = 1;
    sprites = await sheetIWH('game_laser.png', 3, 60);
  }

  // Implementation

  void _recycle(LaserShot it) {
    _pool.add(it);
    it.removeFromParent();
  }

  final _pool = <LaserShot>[];
}

class LaserShot extends SpriteAnimationComponent {
  final Function(LaserShot) _recycle;

  LaserShot(this._recycle, {super.animation}) : super(anchor: Anchor.topCenter);

  double? expire_at;

  reset(SpriteSheet sprites, Vector2 start) {
    animation = sprites.createAnimation(row: 0, stepTime: 0.05, loop: false);
    animationTicker!.reset();
    position.setFrom(start);
    expire_at = null;
  }

  @override
  onLoad() => paint = pixelPaint();

  var _expire_step = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (expire_at != null) {
      if (position.y != expire_at) {
        position.y += (expire_at! - position.y) * dt * 2;
      }
      final ticker = animationTicker!;
      if (_expire_step == 0 && ticker.currentIndex > 0) {
        _expire_step = 0.025;
      } else if (_expire_step > 0) {
        _expire_step -= dt;
        if (_expire_step <= 0) {
          ticker.currentIndex--;
          _expire_step = ticker.currentIndex == 0 ? 0 : 0.05;
        }
      } else {
        _recycle(this);
      }
    } else {
      position.y -= 500 * dt;
      if (position.y < -height) {
        _recycle(this);
      } else {
        final brick = level.find_lowest_brick(position, height);
        brick?.hit();
        expire_at = brick?.topLeft.y;
        if (brick != null) animationTicker!.paused = true;
      }
    }
  }
}
