import 'dart:async';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:kart/kart.dart';

import '../core/common.dart';
import 'soundboard.dart';
import 'storage.dart';

class SoundboardImpl extends Soundboard {
  final _sounds = <Sound, AudioPlayer>{};
  final _web_notes = <AudioPlayer>[];
  final _max_sounds = <AudioPlayer>[];
  final _last_time = <AudioPlayer, int>{};

  @override
  double? get active_music_volume => FlameAudio.bgm.audioPlayer.volume;

  @override
  set active_music_volume(double? it) => FlameAudio.bgm.audioPlayer.setVolume(it ?? music);

  @override
  Future do_play_notes() async {
    super.do_play_notes();
    logInfo('do play notes');
    for (int i = 0; i <= 20; i++) {
      _web_notes.add(await _preload_player('note$i.ogg'));
    }
  }

  @override
  void do_not_play_notes() {
    super.do_not_play_notes();
    logInfo('do not play notes');
    for (final it in _web_notes) {
      it.dispose();
    }
    _web_notes.clear();
  }

  @override
  Future do_init_and_preload() async {
    if (_sounds.isEmpty) await _preload_sounds();
  }

  Future _preload_sounds() async {
    for (final it in Sound.values) {
      try {
        // can't figure out why this one sound does not play in the web version ‾\_('')_/‾
        final ext = it == Sound.enemy_destroyed ? 'mp3' : 'ogg';
        _sounds[it] = await _preload_player('${it.name}.$ext');
      } catch (e) {
        logError('failed loading $it: $e');
      }
    }
    if (brick_notes) do_play_notes();
  }

  Future<AudioPlayer> _preload_player(String name) async {
    final player = await FlameAudio.play('sound/$name', volume: super.sound);
    player.setReleaseMode(ReleaseMode.stop);
    player.setPlayerMode(PlayerMode.lowLatency);
    player.stop();
    return player;
  }

  @override
  void do_update_volume() {
    logInfo('update volume $music');
    final ap = FlameAudio.bgm.audioPlayer;
    if (ap.source == null || !FlameAudio.bgm.isPlaying) return;
    ap.setVolume(music);
    // if (music == 0 && ap.state == PlayerState.playing) FlameAudio.bgm.pause();
    // if (music > 0 && ap.state != PlayerState.playing) FlameAudio.bgm.resume();
  }

  @override
  Future do_play(Sound sound, double volume_factor) async {
    final play_notes = sound == Sound.wall_hit && soundboard.brick_notes;
    final it = play_notes ? _web_notes.getOrNull(note_index ?? 0) : _sounds[sound];
    if (it == null) {
      logError('null sound: $sound');
      preload();
      return;
    }

    final last_played_at = _last_time[it] ?? 0;
    final now = DateTime.timestamp().millisecondsSinceEpoch;
    if (now < last_played_at + 100) return;
    _last_time[it] = now;

    _max_sounds.removeWhere((it) => it.state != PlayerState.playing);
    if (_max_sounds.length > 10) {
      if (dev) logWarn('sound killed - overload');
      final fifo = _max_sounds.removeAt(0);
      await fifo.stop();
    }

    if (it.state != PlayerState.stopped) await it.stop();
    await it.setVolume(volume_factor * super.sound);
    await it.resume();
    note_index = 0;
  }

  @override
  Future do_play_one_shot_sample(String filename, double volume_factor) async {
    await FlameAudio.audioCache.load(filename);
    final it = await FlameAudio.play(filename, volume: volume_factor * super.sound);
    it.setReleaseMode(ReleaseMode.release);
  }

  @override
  Future do_play_music(String filename) async {
    logInfo('playing music via audio_players');
    if (FlameAudio.bgm.isPlaying) {
      logInfo('stopping active bgm');
      await FlameAudio.bgm.stop();
    }
    await FlameAudio.bgm.play(filename, volume: music);
  }

  @override
  void do_stop_active_music() {} // FlameAudio.bgm.dispose();

  // Component

  @override
  onLoad() async {
    super.onLoad();
    await load('soundboard', this);
  }
}
