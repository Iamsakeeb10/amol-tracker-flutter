class QuranSurah {
  const QuranSurah({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameBn,
    required this.nameTransliteration,
    required this.ayahCount,
    required this.type,
    required this.revelationOrder,
    required this.startPage,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String nameBn;
  final String nameTransliteration;
  final int ayahCount;
  final String type;
  final int revelationOrder;
  final int startPage;

  bool get isMeccan => type.toLowerCase() == 'meccan';

  /// Primary list/title label for the current app locale.
  String displayName(String languageCode) {
    if (languageCode == 'bn' && nameBn.isNotEmpty) return nameBn;
    return nameTransliteration;
  }

  /// Secondary subtitle under the primary name (English meaning only).
  String displaySubtitle(String languageCode) {
    if (languageCode == 'bn') return '';
    return nameEn;
  }

  factory QuranSurah.fromMap(Map<String, Object?> map) {
    return QuranSurah(
      id: map['id'] as int,
      nameAr: map['name_ar'] as String? ?? '',
      nameEn: map['name_en'] as String? ?? '',
      nameBn: map['name_bn'] as String? ?? '',
      nameTransliteration: map['name_transliteration'] as String? ?? '',
      ayahCount: map['ayah_count'] as int? ?? 0,
      type: map['type'] as String? ?? '',
      revelationOrder: map['revelation_order'] as int? ?? 0,
      startPage: map['start_page'] as int? ?? 1,
    );
  }
}
