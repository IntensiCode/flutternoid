import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../core/messaging.dart';
import '../util/auto_dispose.dart';
import '../util/on_message.dart';
import 'game_messages.dart';
import 'game_object.dart';
import 'soundboard.dart';
import 'storage.dart';

Future<bool> first_time() async {
  final map = await load_data('first_time');
  if (map == null) return true;
  return map['first_time'] != null;
}

Future save_not_first_time() async => (await save_data('first_time', {'first_time': false}));

final state = GameState();

class GameState extends Component with AutoDispose, HasGameData {
  var level_number_starting_at_1 = 1;
  var _score = 0;
  var lives = 3;
  var blasts = 3;
  bool game_complete = false;

  int get score => _score;

  set score(int value) {
    if (!game_complete) {
      final b4 = _score ~/ 2000;
      final now = value ~/ 2000;
      if (b4 < now) sendMessage(ExtraLife());
    }
    _score = value;
  }

  reset() async {
    logInfo('reset game state');
    level_number_starting_at_1 = 1;
    _score = 0;
    lives = 3;
    blasts = 3;
    game_complete = false;
    logInfo('reset game state: $level_number_starting_at_1 $score $lives $blasts');
  }

  delete() async => await clear('game_state');

  save_checkpoint() async => await save('game_state', this);

  // Component

  @override
  onLoad() async {
    super.onLoad();
    await load('game_state', this);
    logInfo('loaded game state: $level_number_starting_at_1');
    onMessage<ExtraLife>((_) {
      lives++;
      soundboard.play(Sound.extra_life_jingle);
    });
  }

  // HasGameData

  @override
  void load_state(GameData data) {
    level_number_starting_at_1 = data['level_number_starting_at_1'];
    _score = data['score'];
    lives = data['lives'];
    blasts = data['blasts'];
  }

  @override
  GameData save_state(GameData data) => data
    ..['level_number_starting_at_1'] = level_number_starting_at_1
    ..['score'] = _score
    ..['lives'] = lives
    ..['blasts'] = blasts;
}
