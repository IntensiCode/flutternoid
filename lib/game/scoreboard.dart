import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import 'ball.dart';
import 'game_context.dart';
import 'hiscore.dart';
import 'player.dart';
import 'slow_down_area.dart';
import 'soundboard.dart';

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

    // too much 64 :-D
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
  }

  int? display_score;
  int? display_round;
  int? display_lives;
  int? display_blasts;

  double highlight_high_score = 0;
  double highlight_good_score = 0;
  double highlight_round = 0;
  double highlight_lives = 0;
  double highlight_blasts = 0;

  bool show_new_hiscore = false;
  bool blink_high_score = false;
  bool toggle_high_score = false;
  bool blink_ranked_score = false;
  bool toggle_ranked_score = false;

  @override
  void update(double dt) {
    super.update(dt);

    if (display_score != state.score) {
      if (display_score != null) {
        final was = display_score;
        display_score = lerpDouble(display_score!, state.score, 0.1)!.toInt();
        if (display_score == was && display_score! < state.score) {
          display_score = display_score! + 1;
        }
      } else {
        display_score = state.score;
      }

      if (hiscore.isNewHiscore(display_score!)) {
        highlight_high_score = 1;
        highlight_good_score = 0;
        toggle_ranked_score = false;
        if (!show_new_hiscore) {
          soundboard.play_one_shot_sample('sound/hiscore.ogg');
        }
        show_new_hiscore = true;
      } else if (hiscore.isHiscoreRank(display_score!) && highlight_good_score == 0) {
        highlight_good_score = 1;
      }
    }

    if (highlight_high_score > 0) {
      highlight_high_score -= min(highlight_high_score, dt / 3);
      if (highlight_high_score <= 0) {
        highlight_high_score = 1;
      }
      toggle_high_score = highlight_high_score < 0.5;
      blink_high_score = (highlight_high_score % 0.5) < 0.2;
      blink_ranked_score = false;
    }
    if (highlight_good_score > 0) {
      highlight_good_score -= min(highlight_good_score, dt / 3);
      if (highlight_good_score <= 0) {
        highlight_good_score = 1;
      }
      toggle_ranked_score = highlight_good_score < 0.5;
      blink_ranked_score = (highlight_good_score % 0.5) < 0.2;
    }

    if (display_round != state.level_number_starting_at_1) {
      if (display_round != null) highlight_round += 1;
      display_round = state.level_number_starting_at_1;
    }

    if (display_lives != state.lives) {
      if (display_lives != null) highlight_lives += 1;
      display_lives = state.lives;
    }

    if (display_blasts != state.blasts) {
      if (display_blasts != null) highlight_blasts += 1;
      display_blasts = state.blasts;
    }

    if (highlight_round > 0) highlight_round -= min(highlight_round, dt);
    if (highlight_lives > 0) highlight_lives -= min(highlight_lives, dt);
    if (highlight_blasts > 0) highlight_blasts -= min(highlight_blasts, dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    mini_font.paint.opacity = 1;

    fontSelect(mini_font, scale: 1);
    var label = toggle_high_score ? '*** NEW ***' : 'HIGH SCORE';
    mini_font.drawStringAligned(canvas, size.x / 2, 24, label, Anchor.topCenter);

    if (!blink_high_score) {
      final hiscore_ = show_new_hiscore
          ? display_score!.toString().padLeft(7, '0')
          : hiscore.entries.first.score.toString().padLeft(7, '0');
      mini_font.drawStringAligned(canvas, size.x / 2, 32, hiscore_, Anchor.topCenter);
    }

    label = toggle_ranked_score ? 'RANKED #${hiscore.rank(display_score!)}' : 'SCORE';
    mini_font.drawStringAligned(canvas, size.x / 2, 58, label, Anchor.topCenter);

    if (!blink_ranked_score) {
      final score = (display_score ?? state.score).toString().padLeft(7, '0');
      mini_font.drawStringAligned(canvas, size.x / 2, 66, score, Anchor.topCenter);
    }

    final round = state.level_number_starting_at_1.toString().padLeft(2, ' ');
    if (highlight_round > 0) mini_font.paint.opacity = (highlight_round * 4) % 1;
    mini_font.drawStringAligned(canvas, size.x / 2, 76, 'ROUND $round', Anchor.topCenter);
    mini_font.paint.opacity = 1;

    final lives = state.lives.toString().padLeft(2, ' ');
    if (highlight_lives > 0) mini_font.paint.opacity = (highlight_lives * 4) % 1;
    mini_font.drawStringAligned(canvas, size.x / 2, 84, 'LIVES $lives', Anchor.topCenter);
    mini_font.paint.opacity = 1;

    final blasts = state.blasts.toString().padLeft(2, ' ');
    if (highlight_blasts > 0) mini_font.paint.opacity = (highlight_blasts * 4) % 1;
    mini_font.drawStringAligned(canvas, size.x / 2, 92, 'BLAST $blasts', Anchor.topCenter);
    mini_font.paint.opacity = 1;

    if (level.level_time > 0) {
      final bonus = level.level_time.round().toString().padLeft(2, ' ');
      mini_font.drawStringAligned(canvas, size.x / 2, 104, 'BONUS $bonus', Anchor.topCenter);
    }

    final stats = {
      'EXPAND ': player.expanded_seconds,
      'DISRUPT': null,
      'LASER  ': player.laser_seconds,
      'CATCH  ': player.catcher_seconds,
      'SLOW   ': model.slow_down_area.slow_down_seconds,
    };
    final balls = top_level_children<Ball>();
    for (final it in balls) {
      if (it.disruptor == 0) continue;
      stats.update('DISRUPT', (e) => max(e ?? 0, it.disruptor.round()));
    }

    var stats_y = 116.0;
    for (final it in stats.entries) {
      if (it.value == null) continue;
      final line = '${it.key} ${it.value}';
      mini_font.drawStringAligned(canvas, size.x / 2, stats_y, line, Anchor.topCenter);
      stats_y += 12;
    }
  }
}

extension on Player {
  int? get expanded_seconds {
    if (expanded == 0) return null;
    return expanded.round();
  }

  int? get catcher_seconds {
    if (!is_actual_catcher) return null;
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
