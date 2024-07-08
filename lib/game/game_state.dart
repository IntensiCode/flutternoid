import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../core/storage.dart';
import 'game_object.dart';

class GameState extends Component with HasGameData {
  var level_number_starting_at_1 = 1;
  var score = 0;
  var lives = 3;
  var blasts = 3;

  clear_and_reset() async {
    level_number_starting_at_1 = 1;
    score = 0;
    lives = 3;
    blasts = 3;
    await clear('game_state');
  }

  save_checkpoint() async => await save('game_state', this);

  // Component

  @override
  onLoad() async {
    super.onLoad();
    logInfo('load?');
    await load('game_state', this);
    logInfo('loaded game state: $level_number_starting_at_1');
  }

  // HasGameData

  @override
  void load_state(GameData data) {
    level_number_starting_at_1 = data['level_number_starting_at_1'];
    score = data['score'];
    lives = data['lives'];
    blasts = data['blasts'];
  }

  @override
  GameData save_state(GameData data) => data
    ..['level_number_starting_at_1'] = level_number_starting_at_1
    ..['score'] = score
    ..['lives'] = lives
    ..['blasts'] = blasts;
}
