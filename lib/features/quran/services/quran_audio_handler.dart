import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/quran_constants.dart';

typedef QuranPlaybackCallback = void Function(int surahId, int ayah, bool completed);

typedef QuranPlayerStateCallback = void Function({
  required bool playing,
  required bool isBuffering,
  required bool isReady,
});

AudioHandler? _cachedAudioHandler;

class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  QuranAudioHandler() {
    _ready = _init();
  }

  final AudioPlayer _player = AudioPlayer();
  late final Future<void> _ready;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _positionSub;

  int _surahId = 0;
  int _ayah = 0;
  int _totalAyahs = 0;
  String _surahName = '';
  String _qariId = QuranConstants.defaultQariId;
  QuranPlaybackCallback? onAyahChanged;
  QuranPlayerStateCallback? onPlayerStateChanged;

  /// Whether playback should proceed. Set to false on pause, true on play/playAyah.
  bool _shouldPlay = true;

  Future<void> _init() async {
    playbackState.add(
      PlaybackState(
        controls: [MediaControl.play, MediaControl.stop],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _playerStateSub = _player.playerStateStream.listen((state) {
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (state.playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: _mapProcessingState(state.processingState),
          playing: state.playing,
        ),
      );

      onPlayerStateChanged?.call(
        playing: state.playing,
        isBuffering: state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering,
        isReady: state.processingState == ProcessingState.ready ||
            state.processingState == ProcessingState.completed,
      );

      if (state.processingState == ProcessingState.completed) {
        unawaited(_onAyahCompleted());
      }
    });

    _durationSub = _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current == null || duration == null) return;
      mediaItem.add(current.copyWith(duration: duration));
    });

    _positionSub = _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Internal core method. Loads and plays the ayah only if [_shouldPlay] is true.
  /// Call [playAyah] from external APIs (which always sets [_shouldPlay] = true first).
  Future<void> _setupAndPlay({
    required int surahId,
    required int ayah,
    required int totalAyahs,
    required String surahName,
    required String qariId,
  }) async {
    await _ready;

    _surahId = surahId;
    _ayah = ayah;
    _totalAyahs = totalAyahs;
    _surahName = surahName;
    _qariId = qariId;

    final url = QuranConstants.everyAyahUrl(
      qariId: qariId,
      surah: surahId,
      ayah: ayah,
    );

    mediaItem.add(
      MediaItem(
        id: url,
        album: 'Quran',
        title: '$surahName — Ayah $ayah',
        artist: QuranConstants.qariById(qariId).nameEn,
        extras: {
          'surahId': surahId,
          'ayah': ayah,
        },
      ),
    );

    onAyahChanged?.call(surahId, ayah, false);

    try {
      await _player.setUrl(url);
      if (_shouldPlay) {
        await _player.play();
      }
    } catch (e) {
      _shouldPlay = false;
      // Network drop or connection abort. Gracefully stop.
      onPlayerStateChanged?.call(
        playing: false,
        isBuffering: false,
        isReady: false,
      );
    }
  }

  /// Starts playback of a specific ayah. Always plays regardless of prior pause state.
  Future<void> playAyah({
    required int surahId,
    required int ayah,
    required int totalAyahs,
    required String surahName,
    required String qariId,
  }) async {
    _shouldPlay = true;
    await _setupAndPlay(
      surahId: surahId,
      ayah: ayah,
      totalAyahs: totalAyahs,
      surahName: surahName,
      qariId: qariId,
    );
  }

  Future<void> _onAyahCompleted() async {
    if (_surahId <= 0 || _ayah <= 0) return;
    if (_ayah >= _totalAyahs) {
      onAyahChanged?.call(_surahId, _ayah, true);
      await stop();
      return;
    }
    // Use _setupAndPlay instead of playAyah so the _shouldPlay flag is respected.
    // This prevents auto-advance from restarting playback after the user paused.
    await _setupAndPlay(
      surahId: _surahId,
      ayah: _ayah + 1,
      totalAyahs: _totalAyahs,
      surahName: _surahName,
      qariId: _qariId,
    );
  }

  @override
  Future<void> play() async {
    await _ready;
    _shouldPlay = true;
    try {
      await _player.play();
    } catch (_) {
      _shouldPlay = false;
    }
  }

  @override
  Future<void> pause() async {
    await _ready;
    _shouldPlay = false;
    try {
      await _player.pause();
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    await _ready;
    _shouldPlay = false;
    try {
      await _player.stop();
    } catch (_) {}
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _ready;
    try {
      await _player.seek(position);
    } catch (_) {}
  }

  @override
  Future<void> skipToNext() async {
    await _ready;
    if (_surahId <= 0 || _ayah >= _totalAyahs) return;
    await playAyah(
      surahId: _surahId,
      ayah: _ayah + 1,
      totalAyahs: _totalAyahs,
      surahName: _surahName,
      qariId: _qariId,
    );
  }

  @override
  Future<void> skipToPrevious() async {
    await _ready;
    if (_surahId <= 0 || _ayah <= 1) {
      try {
        await _player.seek(Duration.zero);
      } catch (_) {}
      return;
    }
    await playAyah(
      surahId: _surahId,
      ayah: _ayah - 1,
      totalAyahs: _totalAyahs,
      surahName: _surahName,
      qariId: _qariId,
    );
  }

  Future<void> disposeHandler() async {
    await _playerStateSub?.cancel();
    await _durationSub?.cancel();
    await _positionSub?.cancel();
    await _player.dispose();
  }
}

@pragma('vm:entry-point')
Future<AudioHandler> initQuranAudioHandler() async {
  if (_cachedAudioHandler != null) {
    return _cachedAudioHandler!;
  }

  _cachedAudioHandler = await AudioService.init(
    builder: QuranAudioHandler.new,
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.shakib.amol.quran',
      androidNotificationChannelName: 'Quran Recitation',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
    ),
  );
  return _cachedAudioHandler!;
}
