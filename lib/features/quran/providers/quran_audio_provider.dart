import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../../../core/services/analytics_service.dart';
import '../models/quran_audio_state.dart';
import '../models/quran_surah.dart';
import '../services/quran_audio_handler.dart';
import 'quran_reading_prefs_provider.dart';
import 'quran_surah_provider.dart';

final quranAudioHandlerProvider = FutureProvider<AudioHandler>((ref) async {
  ref.keepAlive();
  return initQuranAudioHandler();
});

class QuranAudioNotifier extends StateNotifier<QuranAudioState> {
  QuranAudioNotifier(this.ref) : super(const QuranAudioState());

  final Ref ref;
  QuranAudioHandler? _handler;
  bool _initialized = false;

  Future<QuranAudioHandler> _ensureHandler() async {
    if (_handler != null) return _handler!;
    final handler = await ref.read(quranAudioHandlerProvider.future);
    _handler = handler as QuranAudioHandler;
    if (!_initialized) {
      _handler!.onAyahChanged = _onAyahChanged;
      _handler!.onPlayerStateChanged = _onPlayerStateChanged;
      _initialized = true;
    }
    return _handler!;
  }

  void _onPlayerStateChanged({
    required bool playing,
    required bool isBuffering,
    required bool isReady,
  }) {
    if (!state.isActive && !state.isLoading) return;

    final bool? nextLoading;
    if (isBuffering) {
      nextLoading = true;
    } else if (isReady) {
      nextLoading = false;
    } else {
      nextLoading = null;
    }

    state = state.copyWith(
      isPlaying: playing,
      isLoading: nextLoading ?? state.isLoading,
      hasError: false,
    );
  }

  void _onAyahChanged(int surahId, int ayah, bool completed) {
    if (completed) {
      state = state.copyWith(
        surahId: surahId,
        ayah: ayah,
        isPlaying: false,
        isLoading: false,
        hasError: false,
      );
      return;
    }
    state = state.copyWith(
      surahId: surahId,
      ayah: ayah,
      hasError: false,
    );
  }

  Future<void> playSurah(QuranSurah surah, {int startAyah = 1}) async {
    final prefs = ref.read(quranReadingPrefsProvider);
    state = state.copyWith(
      surahId: surah.id,
      ayah: startAyah,
      qariId: prefs.qari,
      isLoading: true,
      hasError: false,
      isPlaying: false,
      surahName: surah.nameTransliteration,
      surahNameBn: surah.nameBn,
      totalAyahs: surah.ayahCount,
    );

    try {
      final handler = await _ensureHandler();
      await handler.playAyah(
        surahId: surah.id,
        ayah: startAyah,
        totalAyahs: surah.ayahCount,
        surahName: surah.nameTransliteration,
        qariId: prefs.qari,
      );
    } catch (error, stackTrace) {
      AnalyticsService.instance.recordError(
        error,
        stackTrace,
        reason: 'Quran audio playback failed',
      );
      state = state.copyWith(isLoading: false, hasError: true, isPlaying: false);
    }
  }

  Future<void> playSurahById(int surahId, {int startAyah = 1}) async {
    final surah = await ref.read(quranSurahByIdProvider(surahId).future);
    if (surah == null) return;
    await playSurah(surah, startAyah: startAyah);
  }

  Future<void> togglePlayPause() async {
    final handler = await _ensureHandler();
    if (state.isPlaying) {
      await handler.pause();
      return;
    }
    if (state.isActive) {
      await handler.play();
    }
  }

  Future<void> stop() async {
    final handler = await _ensureHandler();
    await handler.stop();
    state = const QuranAudioState();
  }

  Future<void> nextAyah() async {
    final handler = await _ensureHandler();
    await handler.skipToNext();
  }

  Future<void> previousAyah() async {
    final handler = await _ensureHandler();
    await handler.skipToPrevious();
  }

  Future<void> setQari(String qariId) async {
    await ref.read(quranReadingPrefsProvider.notifier).setQari(qariId);
    if (!state.isActive) {
      state = state.copyWith(qariId: qariId);
      return;
    }
    final surah = await ref.read(quranSurahByIdProvider(state.surahId).future);
    if (surah == null) return;
    await playSurah(surah, startAyah: state.ayah);
  }
}

final quranAudioProvider =
    StateNotifierProvider<QuranAudioNotifier, QuranAudioState>(
  QuranAudioNotifier.new,
);
