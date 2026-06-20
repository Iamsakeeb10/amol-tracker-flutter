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
    this.showTranslation = true,
    this.lastMushafPage = 1,
    this.mushafReaderMode = false,
  });

  final QuranTranslator translator;
  final String qari;
  final double arabicFontScale;
  final bool showTranslation;
  final int lastMushafPage;
  final bool mushafReaderMode;

  QuranReadingPrefs copyWith({
    QuranTranslator? translator,
    String? qari,
    double? arabicFontScale,
    bool? showTranslation,
    int? lastMushafPage,
    bool? mushafReaderMode,
  }) {
    return QuranReadingPrefs(
      translator: translator ?? this.translator,
      qari: qari ?? this.qari,
      arabicFontScale: arabicFontScale ?? this.arabicFontScale,
      showTranslation: showTranslation ?? this.showTranslation,
      lastMushafPage: lastMushafPage ?? this.lastMushafPage,
      mushafReaderMode: mushafReaderMode ?? this.mushafReaderMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'translator': translator.index,
      'qari': qari,
      'arabicFontScale': arabicFontScale,
      'showTranslation': showTranslation,
      'lastMushafPage': lastMushafPage,
      'mushafReaderMode': mushafReaderMode,
    };
  }

  factory QuranReadingPrefs.fromJson(Map<String, dynamic> json) {
    final translatorIndex =
        (json['translator'] as int? ?? 0).clamp(0, QuranTranslator.values.length - 1);
    return QuranReadingPrefs(
      translator: QuranTranslator.values[translatorIndex],
      qari: json['qari'] as String? ?? QuranConstants.defaultQariId,
      arabicFontScale: (json['arabicFontScale'] as num?)?.toDouble() ?? 1.0,
      showTranslation: json['showTranslation'] as bool? ?? true,
      lastMushafPage: (json['lastMushafPage'] as int? ?? 1)
          .clamp(1, QuranConstants.mushafPageCount),
      mushafReaderMode: json['mushafReaderMode'] as bool? ?? false,
    );
  }
}
