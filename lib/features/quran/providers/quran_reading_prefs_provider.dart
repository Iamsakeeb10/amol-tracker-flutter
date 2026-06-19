import 'package:riverpod/legacy.dart';

import '../../../core/services/local_storage_service.dart';
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

  Future<void> setLastPage(int page) async {
    state = state.copyWith(lastPage: page.clamp(1, 604));
    await _persist();
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

  Future<void> setShowTranslation(bool value) async {
    state = state.copyWith(showTranslation: value);
    await _persist();
  }

  Future<void> setReadingMode(QuranReadingMode mode) async {
    state = state.copyWith(readingMode: mode);
    await _persist();
  }
}

final quranReadingPrefsProvider =
    StateNotifierProvider<QuranReadingPrefsNotifier, QuranReadingPrefs>(
  (ref) => QuranReadingPrefsNotifier(),
);
