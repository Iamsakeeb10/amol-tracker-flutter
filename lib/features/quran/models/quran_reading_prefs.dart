import '../constants/quran_constants.dart';

enum QuranReadingMode { mushaf, scroll }

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
    this.lastPage = 1,
    this.translator = QuranTranslator.khan,
    this.qari = QuranConstants.defaultQariId,
    this.arabicFontScale = 1.0,
    this.showTranslation = true,
    this.readingMode = QuranReadingMode.mushaf,
  });

  final int lastPage;
  final QuranTranslator translator;
  final String qari;
  final double arabicFontScale;
  final bool showTranslation;
  final QuranReadingMode readingMode;

  QuranReadingPrefs copyWith({
    int? lastPage,
    QuranTranslator? translator,
    String? qari,
    double? arabicFontScale,
    bool? showTranslation,
    QuranReadingMode? readingMode,
  }) {
    return QuranReadingPrefs(
      lastPage: lastPage ?? this.lastPage,
      translator: translator ?? this.translator,
      qari: qari ?? this.qari,
      arabicFontScale: arabicFontScale ?? this.arabicFontScale,
      showTranslation: showTranslation ?? this.showTranslation,
      readingMode: readingMode ?? this.readingMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastPage': lastPage,
      'translator': translator.index,
      'qari': qari,
      'arabicFontScale': arabicFontScale,
      'showTranslation': showTranslation,
      'readingMode': readingMode.index,
    };
  }

  factory QuranReadingPrefs.fromJson(Map<String, dynamic> json) {
    final translatorIndex =
        (json['translator'] as int? ?? 0).clamp(0, QuranTranslator.values.length - 1);
    final modeIndex =
        (json['readingMode'] as int? ?? 0).clamp(0, QuranReadingMode.values.length - 1);
    return QuranReadingPrefs(
      lastPage: json['lastPage'] as int? ?? 1,
      translator: QuranTranslator.values[translatorIndex],
      qari: json['qari'] as String? ?? QuranConstants.defaultQariId,
      arabicFontScale: (json['arabicFontScale'] as num?)?.toDouble() ?? 1.0,
      showTranslation: json['showTranslation'] as bool? ?? true,
      readingMode: QuranReadingMode.values[modeIndex],
    );
  }
}
