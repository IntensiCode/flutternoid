import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../core/messaging.dart';
import '../util/auto_dispose.dart';
import 'game_messages.dart';
import 'game_object.dart';
import 'hiscore.dart';
import 'storage.dart';

Future<bool> first_time() async {
  final map = await load_data('first_time');
  if (map == null) return true;
  logInfo('first time data: $map');
  return map['first_time'] != false;
}

Future save_not_first_time() async {
  await save_data('first_time', {'first_time': false});
}

final state = GameState();

const extra_life_score = 3333;

class GameState extends Component with AutoDispose, HasGameData {
  var level_number_starting_at_1 = 1;
  var _last_extra_at = 0;
  var _score = 0;
  var lives = 5;
  var blasts = 5;
  bool game_complete = false;

  int get score => _score;

  set score(int value) {
    if (!game_complete) {
      final next_extra = _last_extra_at + 3000 + level_number_starting_at_1 * 100;
      final b4 = _score < next_extra;
      final now = value >= next_extra;
      if (b4 && now) {
        logInfo('extra life: last_extra_at=$_last_extra_at next_extra=$next_extra score=$_score');
        _last_extra_at = _score;
        sendMessage(ExtraLife());
      }
    }
    _score = value;
  }

  hack_hiscore() => _score = hiscore.entries.last.score + 1;

  reset() async {
    logInfo('reset game state');
    level_number_starting_at_1 = 1;
    _last_extra_at = 0;
    _score = 0;
    lives = 5;
    blasts = 5;
    game_complete = false;
  }

  preload() async {
    await load('game_state', this);
    logInfo('loaded game state: $level_number_starting_at_1');
  }

  delete() async {
    logInfo('delete game state');
    await clear('game_state');
  }

  save_checkpoint() async {
    logInfo('save game state');
    await save('game_state', this);
  }

  // HasGameData

  @override
  void load_state(GameData data) {
    level_number_starting_at_1 = data['level_number_starting_at_1'];
    _last_extra_at = data['last_extra_at'];
    _score = data['score'];
    lives = data['lives'];
    blasts = data['blasts'];
  }

  @override
  GameData save_state(GameData data) => data
    ..['level_number_starting_at_1'] = level_number_starting_at_1
    ..['last_extra_at'] = _last_extra_at
    ..['score'] = _score
    ..['lives'] = lives
    ..['blasts'] = blasts;
}
