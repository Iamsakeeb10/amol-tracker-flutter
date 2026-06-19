import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/quran_constants.dart';

typedef QuranPlaybackCallback = void Function(int surahId, int ayah, bool completed);

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

  Future<void> playAyah({
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

    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> _onAyahCompleted() async {
    if (_surahId <= 0 || _ayah <= 0) return;
    if (_ayah >= _totalAyahs) {
      onAyahChanged?.call(_surahId, _ayah, true);
      await stop();
      return;
    }
    await playAyah(
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
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _ready;
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _ready;
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _ready;
    await _player.seek(position);
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
      await _player.seek(Duration.zero);
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
