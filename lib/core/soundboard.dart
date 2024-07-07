import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';

import 'common.dart';

enum Sound {
  ball_held,
  ball_lost,
  bat_expand,
  catcher,
  disruptor,
  expander,
  explosion,
  extra_life,
  game_over,
  get_ready,
  hiscore,
  laser,
  laser_shot,
  level_complete,
  multi_ball,
  plasma,
  slow_down,
  wall_hit,
}

final soundboard = Soundboard();

double get musicVolume => soundboard.music * soundboard.master;

class Soundboard extends Component {
  double master = 0.75;
  double _music = 0.5;
  double voice = 0.8;
  double sound = 0.6;

  double get music => _music;

  set music(double value) {
    _music = value;
    bgm?.setVolume(_music * master);
  }

  bool muted = false;

  // flag used during initialization
  bool _blocked = false;

  // used by [trigger] to play every sound only once per tick
  final _triggered = <Sound>{};

  // raw sample data for mixing
  final _samples = <Sound, Float32List>{};

  // some notes to play instead of wall hit
  final _notes = <Float32List>[];

  // constant audio stream for mixing sound effects
  AudioStream? _stream;

  // sample states for mixing into [_stream]
  final _play_state = <(Float32List, int)>[];

  int? note_index;

  toggleMute() {
    muted = !muted;
    if (muted) {
      if (bgm?.state == PlayerState.playing) bgm?.pause();
    } else {
      if (bgm?.state == PlayerState.paused) bgm?.resume();
    }
  }

  clear(String filename) => FlameAudio.audioCache.clear(filename);

  preload() async {
    logInfo('preload audio');

    _blocked = true;

    if (_samples.isEmpty) {
      for (final it in Sound.values) {
        logInfo('preload sample $it');
        final bytes = await game.assets.readBinaryFile('audio/sound/${it.name}.raw');
        final data = Float32List(bytes.length);
        for (int i = 0; i < bytes.length; i++) {
          data[i] = ((bytes[i] / 128) - 1) * 0.8;
        }
        _samples[it] = data;
      }
    }

    if (_stream == null) {
      logInfo('start audio mixing stream');
      _stream = getAudioStream();
      final result = _stream!.init(
        bufferMilliSec: 500,
        waitingBufferMilliSec: 10,
        channels: 1,
        sampleRate: 11025,
      );
      logInfo('audio mixing stream started: $result');
      _stream!.resume();
      _mix_stream();
    }

    _blocked = false;
  }

  trigger(Sound sound) => _triggered.add(sound);

  int last = 0;

  play(Sound sound, {double? volume}) async {
    if (muted) return;
    if (_blocked) return;
    if (_samples.isEmpty) {
      preload();
    } else if (sound == Sound.wall_hit) {
      final index = note_index ?? 0;
      if (_notes.length <= index) {
        for (int i = _notes.length; i <= index; i++) {
          final freq = 261.626 + i * (293.665 - 261.626);
          final wave = _synth_sine_wave(freq, 11025, const Duration(milliseconds: 50));
          _notes.add(wave);
        }
      }
      _play_state.add((_notes[note_index ?? 0], 0));
    } else {
      _play_state.add((_samples[sound]!, 0));
    }
  }

  Future<AudioPlayer> playAudio(String filename, {double? volume}) async {
    volume ??= sound;
    final player = await FlameAudio.play(filename, volume: volume * master);
    if (muted) player.setVolume(0);
    return player;
  }

  AudioPlayer? bgm;

  Future<AudioPlayer> playBackgroundMusic(String filename) async {
    bgm?.stop();

    final volume = music * master;
    if (dev) {
      bgm = await FlameAudio.playLongAudio(filename, volume: volume);

      // only in dev: stop music after 10 seconds, to avoid playing multiple times on hot restart.
      // final afterTenSeconds = player.onPositionChanged.where((it) => it.inSeconds >= 10).take(1);
      // autoDispose('afterTenSeconds', afterTenSeconds.listen((it) => player.stop()));
    } else {
      await FlameAudio.bgm.play(filename, volume: volume);
      bgm = FlameAudio.bgm.audioPlayer;
    }

    if (muted) bgm!.pause();

    return bgm!;
  }

  // Component

  @override
  update(double dt) {
    super.update(dt);
    if (_triggered.isEmpty) return;
    _triggered.forEach(play);
    _triggered.clear();
  }

  // Implementation

  static Float32List _synth_sine_wave(double freq, int rate, Duration duration) {
    final length = duration.inMilliseconds * rate ~/ 1000;

    final fadeSamples = min(100, length ~/ 2);

    final sineWave = List.generate(length, (i) {
      final amp = sin(2 * pi * ((i * freq) % rate) / rate);

      // apply fade in/out to avoid click noise
      final volume = (i > length - fadeSamples)
          ? (length - i - 1) / fadeSamples
          : (i < fadeSamples)
              ? i / fadeSamples
              : 1.0;

      return amp * volume * 0.8;
    });

    return Float32List.fromList(sineWave);
  }

  _mix_stream() async {
    const hz = 10;
    const rate = 11025;
    const step = rate ~/ hz;
    final mixed = Float32List(step);
    logInfo('mixing at $hz hz - frame step $step - buffer bytes ${mixed.length}');

    Timer.periodic(const Duration(milliseconds: 1000 ~/ hz), (t) {
      mixed.fillRange(0, mixed.length, 0);
      if (_play_state.isEmpty) {
        _stream!.push(mixed);
        return;
      }

      double? compress;
      for (final (idx, it) in _play_state.indexed) {
        final data = it.$1;
        final start = it.$2;
        final end = min(start + step, data.length);
        for (int i = start; i < end; i++) {
          final at = i - start;
          mixed[at] += data[i];
          if (mixed[at].abs() > 1) {
            compress = max(compress ?? 0, mixed[at].abs());
          }
        }
        if (end == data.length) {
          _play_state[idx] = (it.$1, -1);
        } else {
          _play_state[idx] = (it.$1, it.$2 + step);
        }
      }
      if (compress != null) {
        logInfo('need compression: $compress');
        for (int i = 0; i < mixed.length; i++) {
          mixed[i] /= compress;
        }
      }
      _stream!.push(mixed);
      _play_state.removeWhere((e) => e.$2 == -1);
    });
  }
}

// TODO Replace AudioPlayer result type with AudioHandle to change stop into fade out etc
