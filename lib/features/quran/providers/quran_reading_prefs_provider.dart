import 'package:riverpod/legacy.dart';

import '../../../core/services/local_storage_service.dart';
import '../constants/quran_constants.dart';
import '../models/quran_reading_prefs.dart';

const _prefsKey = 'quran_reading_prefs';

class QuranReadingPrefsNotifier extends StateNotifier<QuranReadingPrefs> {
  QuranReadingPrefsNotifier() : super(_loadPrefs());

  static QuranReadingPrefs _loadPrefs() {
    final raw = LocalStorageService.getPref<Map<dynamic, dynamic>>(
      _prefsKey,
      const {},
    );
    if (raw.isEmpty) return const QuranReadingPrefs();
    return QuranReadingPrefs.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> _persist() async {
    await LocalStorageService.setPref(_prefsKey, state.toJson());
  }

  Future<void> setTranslator(QuranTranslator translator) async {
    state = state.copyWith(translator: translator);
    await _persist();
  }

  Future<void> setQari(String qariId) async {
    state = state.copyWith(qari: qariId);
    await _persist();
  }

  Future<void> increaseFontScale() async {
    final next = (state.arabicFontScale + 0.08).clamp(0.8, 1.6);
    state = state.copyWith(arabicFontScale: next);
    await _persist();
  }

  Future<void> decreaseFontScale() async {
    final next = (state.arabicFontScale - 0.08).clamp(0.8, 1.6);
    state = state.copyWith(arabicFontScale: next);
    await _persist();
  }

  Future<void> setArabicFontScale(double value) async {
    final next = value.clamp(0.8, 1.6);
    if (state.arabicFontScale == next) return;
    state = state.copyWith(arabicFontScale: next);
    await _persist();
  }

  Future<void> increaseTranslationFontScale() async {
    final next = (state.translationFontScale + 0.08).clamp(0.8, 1.4);
    state = state.copyWith(translationFontScale: next);
    await _persist();
  }

  Future<void> decreaseTranslationFontScale() async {
    final next = (state.translationFontScale - 0.08).clamp(0.8, 1.4);
    state = state.copyWith(translationFontScale: next);
    await _persist();
  }

  Future<void> setTranslationFontScale(double value) async {
    final next = value.clamp(0.8, 1.4);
    if (state.translationFontScale == next) return;
    state = state.copyWith(translationFontScale: next);
    await _persist();
  }

  Future<void> setShowTranslation(bool value) async {
    state = state.copyWith(showTranslation: value);
    await _persist();
  }

  Future<void> setLastMushafPage(int page) async {
    final clamped = page.clamp(1, QuranConstants.mushafPageCount);
    if (state.lastMushafPage == clamped) return;
    state = state.copyWith(lastMushafPage: clamped);
    await _persist();
  }

  Future<void> setMushafReaderMode(bool enabled) async {
    if (state.mushafReaderMode == enabled) return;
    state = state.copyWith(mushafReaderMode: enabled);
    await _persist();
  }

  Future<void> setMushafBgIndex(int index) async {
    final clamped = index.clamp(0, 5);
    if (state.mushafBgIndex == clamped) return;
    state = state.copyWith(mushafBgIndex: clamped);
    await _persist();
  }

  Future<void> setLastReadAyah(int surahId, int ayah) async {
    if (ayah <= 0) return;
    final current = state.lastReadAyahBySurah[surahId];
    if (current == ayah) return;
    state = state.copyWith(
      lastReadAyahBySurah: {
        ...state.lastReadAyahBySurah,
        surahId: ayah,
      },
    );
    await _persist();
  }
}

final quranReadingPrefsProvider =
    StateNotifierProvider<QuranReadingPrefsNotifier, QuranReadingPrefs>(
  (ref) => QuranReadingPrefsNotifier(),
);
