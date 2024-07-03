import 'package:flame/components.dart';

import 'game_object.dart';

class GameState extends Component with HasGameData {
  @override
  load_state(GameData data) {}

  @override
  GameData save_state(GameData data) => throw UnimplementedError();
}
