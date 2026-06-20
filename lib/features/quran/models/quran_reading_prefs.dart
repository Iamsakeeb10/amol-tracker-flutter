import '../constants/quran_constants.dart';

enum QuranTranslator { khan, sahih }

extension QuranTranslatorKey on QuranTranslator {
  String get dbKey {
    switch (this) {
      case QuranTranslator.khan:
        return QuranConstants.translatorKhan;
      case QuranTranslator.sahih:
        return QuranConstants.translatorSahih;
    }
  }
}

class QuranReadingPrefs {
  const QuranReadingPrefs({
    this.translator = QuranTranslator.khan,
    this.qari = QuranConstants.defaultQariId,
    this.arabicFontScale = 1.0,
    this.translationFontScale = 1.0,
    this.showTranslation = true,
    this.lastMushafPage = 1,
    this.mushafReaderMode = false,
    this.mushafBgIndex = 0,
    this.lastReadAyahBySurah = const {},
  });

  final QuranTranslator translator;
  final String qari;
  final double arabicFontScale;
  final double translationFontScale;
  final bool showTranslation;
  final int lastMushafPage;
  final bool mushafReaderMode;
  final int mushafBgIndex;
  final Map<int, int> lastReadAyahBySurah;

  QuranReadingPrefs copyWith({
    QuranTranslator? translator,
    String? qari,
    double? arabicFontScale,
    double? translationFontScale,
    bool? showTranslation,
    int? lastMushafPage,
    bool? mushafReaderMode,
    int? mushafBgIndex,
    Map<int, int>? lastReadAyahBySurah,
  }) {
    return QuranReadingPrefs(
      translator: translator ?? this.translator,
      qari: qari ?? this.qari,
      arabicFontScale: arabicFontScale ?? this.arabicFontScale,
      translationFontScale: translationFontScale ?? this.translationFontScale,
      showTranslation: showTranslation ?? this.showTranslation,
      lastMushafPage: lastMushafPage ?? this.lastMushafPage,
      mushafReaderMode: mushafReaderMode ?? this.mushafReaderMode,
      mushafBgIndex: mushafBgIndex ?? this.mushafBgIndex,
      lastReadAyahBySurah: lastReadAyahBySurah ?? this.lastReadAyahBySurah,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'translator': translator.index,
      'qari': qari,
      'arabicFontScale': arabicFontScale,
      'translationFontScale': translationFontScale,
      'showTranslation': showTranslation,
      'lastMushafPage': lastMushafPage,
      'mushafReaderMode': mushafReaderMode,
      'mushafBgIndex': mushafBgIndex,
      'lastReadAyahBySurah': lastReadAyahBySurah.map(
        (key, value) => MapEntry('$key', value),
      ),
    };
  }

  factory QuranReadingPrefs.fromJson(Map<String, dynamic> json) {
    final translatorIndex =
        (json['translator'] as int? ?? 0).clamp(0, QuranTranslator.values.length - 1);
    final rawLastRead = json['lastReadAyahBySurah'];
    final lastReadAyahBySurah = <int, int>{};
    if (rawLastRead is Map) {
      rawLastRead.forEach((key, value) {
        final surahId = int.tryParse('$key');
        final ayah = value is int ? value : int.tryParse('$value');
        if (surahId != null && ayah != null && ayah > 0) {
          lastReadAyahBySurah[surahId] = ayah;
        }
      });
    }

    return QuranReadingPrefs(
      translator: QuranTranslator.values[translatorIndex],
      qari: json['qari'] as String? ?? QuranConstants.defaultQariId,
      arabicFontScale: (json['arabicFontScale'] as num?)?.toDouble() ?? 1.0,
      translationFontScale:
          (json['translationFontScale'] as num?)?.toDouble() ?? 1.0,
      showTranslation: json['showTranslation'] as bool? ?? true,
      lastMushafPage: (json['lastMushafPage'] as int? ?? 1)
          .clamp(1, QuranConstants.mushafPageCount),
      mushafReaderMode: json['mushafReaderMode'] as bool? ?? false,
      mushafBgIndex: (json['mushafBgIndex'] as int? ?? 0).clamp(0, 5),
      lastReadAyahBySurah: lastReadAyahBySurah,
    );
  }
}
