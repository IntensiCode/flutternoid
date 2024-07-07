import 'dart:convert';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flutternoid/game/game_object.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _prefs = SharedPreferences.getInstance();

Future save(String name, HasGameData it) async => save_data(name, it.save_state({}));

Future load(String name, HasGameData it) async {
  final data = await load_data(name);
  if (data != null) it.load_state(data);
}

Future save_data(String name, GameData data) async {
  try {
    final preferences = await _prefs;
    preferences.setString(name, jsonEncode(data));
  } catch (it, trace) {
    logError('Failed to store $name: $it', trace);
  }
}

Future<GameData?> load_data(String name) async {
  try {
    final preferences = await _prefs;
    if (!preferences.containsKey(name)) {
      logInfo('no data for $name');
      return null;
    }

    final json = preferences.getString(name);
    if (json == null) {
      logError('invalid data for $name');
      return null;
    }

    logVerbose(json);
    return jsonDecode(json);
  } catch (it, trace) {
    logError('Failed to restore $name: $it', trace);
    return null;
  }
}
