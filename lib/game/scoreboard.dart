import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutternoid/game/game_context.dart';
import 'package:flutternoid/game/hiscore.dart';
import 'package:flutternoid/game/slow_down_area.dart';
import 'package:flutternoid/scripting/game_script_functions.dart';
import 'package:flutternoid/util/auto_dispose.dart';
import 'package:flutternoid/util/fonts.dart';

import '../core/common.dart';
import '../core/functions.dart';
import 'ball.dart';
import 'player.dart';

class Scoreboard extends PositionComponent with AutoDispose, HasVisibility, GameScriptFunctions {
  @override
  onLoad() async {
    super.onLoad();

    size.setValues(320 - 216, gameHeight);
    position.setValues(216, 0);

    await add(await sprite_comp(
      'scoreboard_title.png',
      position: Vector2(size.x / 2, 0),
      anchor: Anchor.topCenter,
    ));

    // fontSelect(fancy_font, scale: 1);
    // await add(textXY('PLAYER 1', size.x / 2, 41, anchor: Anchor.topCenter));
    // await add(textXY('########', size.x / 2, 51, anchor: Anchor.topCenter));
    // await add(textXY('#      #', size.x / 2, 62, anchor: Anchor.topCenter));
    // await add(textXY('#      #', size.x / 2, 73, anchor: Anchor.topCenter));
    // await add(textXY('#      #', size.x / 2, 84, anchor: Anchor.topCenter));
    // await add(textXY('#      #', size.x / 2, 95, anchor: Anchor.topCenter));
    // await add(textXY('########', size.x / 2, 106, anchor: Anchor.topCenter));

    fontSelect(fancy_font, scale: 1);
    await add(textXY('PLAYER 1', size.x / 2, 45, anchor: Anchor.topCenter));

    fontSelect(mini_font, scale: 1);
    await add(textXY('HIGH SCORE', size.x / 2, 24, anchor: Anchor.topCenter));
    final hiscore_ = hiscore.entries.first.score.toString().padLeft(7, '0');
    await add(textXY(hiscore_, size.x / 2, 32, anchor: Anchor.topCenter));

    await add(textXY('SCORE', size.x / 2, 58, anchor: Anchor.topCenter));
    final score = state.score.toString().padLeft(7, '0');
    await add(textXY(score, size.x / 2, 66, anchor: Anchor.topCenter));
    final lives = state.lives.toString().padLeft(2, ' ');
    await add(textXY('LIVES $lives', size.x / 2, 74, anchor: Anchor.topCenter));
    final blasts = state.blasts.toString().padLeft(2, ' ');
    await add(textXY('BLAST $blasts', size.x / 2, 82, anchor: Anchor.topCenter));
    final round = state.level_number_starting_at_1.toString().padLeft(2, ' ');
    await add(textXY('ROUND $round', size.x / 2, 90, anchor: Anchor.topCenter));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final stats = {
      'EXPAND': player.expanded_seconds,
      'DISRUPTOR': null,
      'LASER': player.laser_seconds,
      'CATCHER': player.catcher_seconds,
      'SLOW': model.slow_down_area.slow_down_seconds,
    };
    final balls = top_level_children<Ball>();
    for (final it in balls) {
      if (it.disruptor == 0) continue;
      stats.update('DISRUPTOR', (e) => max(e??0, it.disruptor.round()));
    }

    var stats_y = 106.0;
    for (final it in stats.entries) {
      if (it.value == null) continue;
      final line = '${it.key} ${it.value}';
      mini_font.drawStringAligned(canvas, size.x / 2, stats_y, line, Anchor.topCenter);
      stats_y += 8;
    }
  }
}

extension on Player {
  int? get expanded_seconds {
    if (expanded == 0) return null;
    return expanded.round();
  }

  int? get catcher_seconds {
    if (!in_catcher_mode) return null;
    if (mode_time == 0) return null;
    return mode_time.round();
  }

  int? get laser_seconds {
    if (!in_laser_mode) return null;
    if (mode_time == 0) return null;
    return mode_time.round();
  }
}

extension on SlowDownArea {
  int? get slow_down_seconds {
    if (slow_down_time == 0) return null;
    return slow_down_time.round();
  }
}
