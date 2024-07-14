import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../core/messaging.dart';
import '../core/random.dart';
import 'soundboard.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/on_message.dart';
import 'brick.dart';
import 'extra_id.dart';
import 'game_context.dart';
import 'game_messages.dart';
import 'player.dart';

class SpawnExtra with Message {
  final ExtraId id;

  SpawnExtra(this.id);
}

class PowerUps extends Component with AutoDispose {
  late final SpriteSheet sprites;

  // Component

  @override
  onLoad() async {
    priority = 1;
    sprites = await sheetIWH('game_extras.png', 10, 7);
  }

  @override
  void onMount() {
    super.onMount();
    onMessage<SpawnExtra>((it) => _spawn(it.id));
    onMessage<SpawnExtraFromBrick>((it) => _spawn_power_up(it.brick));
    onMessage<LevelComplete>((_) => removeAll(children));
    onMessage<EnterRound>((_) => removeAll(children));
  }

  // Implementation

  void _spawn(ExtraId id) {
    final it = _pool.removeLastOrNull() ?? PowerUp(_recycle);
    it.reset(sprites, id, Vector2(player.position.x, player.position.y - 50.0));
    add(it);
  }

  void _spawn_power_up(Brick origin) {
    logVerbose('spawning power up from $origin');
    final it = _pool.removeLastOrNull() ?? PowerUp(_recycle);
    final id = _pick_power_up(origin);
    if (id == null) return;
    it.reset(sprites, id, origin.spawn_center);
    add(it);
  }

  ExtraId? _pick_power_up(Brick brick) {
    final allowed = brick.extra_id ?? brick.id.extras;
    if (allowed.isEmpty) return null;

    // pick random power up, based on probabilities in _extras:

    final extras = <(ExtraId, double)>[];
    var added_probability = 0.0;
    for (final it in allowed) {
      added_probability += it.probability;
      extras.add((it, added_probability));
    }

    final all = extras.last.$2;
    final pick = rng.nextDoubleLimit(all);
    for (final it in extras) {
      if (pick < it.$2) return it.$1;
    }
    throw 'oh really?';
  }

  void _recycle(PowerUp it) {
    _pool.add(it);
    it.removeFromParent();
  }

  final _pool = <PowerUp>[];
}

class PowerUp extends SpriteAnimationComponent {
  final Function(PowerUp) _recycle;

  PowerUp(this._recycle) : super(anchor: Anchor.center);

  late ExtraId id;

  late final Player _player;

  var fade_out = 0.0;

  reset(SpriteSheet sprites, ExtraId extra_id, Vector2 start) {
    animation = sprites.createAnimation(row: extra_id.index, stepTime: 0.1);
    id = extra_id;
    position.setFrom(start);
    fade_out = 0.0;
    paint.opacity = 1.0;
  }

  @override
  onLoad() {
    _player = player;
    paint = pixelPaint();
  }

  final _dist = Vector2.zero();

  @override
  void update(double dt) {
    super.update(dt);
    position.y += 30 * dt;
    if (position.y > visual.game_pixels.y) {
      _recycle(this);
    } else if (fade_out > 0.0) {
      paint.opacity = fade_out.clamp(0.0, 1.0);
      fade_out -= dt * 4;
      if (fade_out <= 0.0) _recycle(this);
    } else if (_player.state == PlayerState.playing) {
      _player.distance_and_closest(position, _dist);
      _dist.sub(position);
      _dist.absolute();
      if (_dist.x < width / 3 && _dist.y < height / 3) {
        _notify_consumed();
        fade_out = 1.0;
      }
    }
  }

  void _notify_consumed() {
    final message = switch (id) {
      ExtraId.catcher => Catcher(),
      ExtraId.disruptor => Disruptor(),
      ExtraId.expander => Expander(),
      ExtraId.extra_life => ExtraLife(),
      ExtraId.laser => Laser(),
      ExtraId.multi_ball => MultiBall(),
      ExtraId.slow_down => SlowDown(),
    };
    sendMessage(message);

    soundboard.trigger(switch (id) {
      ExtraId.laser => Sound.laser,
      ExtraId.catcher => Sound.catcher,
      ExtraId.disruptor => Sound.disruptor,
      ExtraId.expander => Sound.expander,
      ExtraId.extra_life => Sound.extra_life,
      ExtraId.multi_ball => Sound.multi_ball,
      ExtraId.slow_down => Sound.slow_down,
    });
  }
}
