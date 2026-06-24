import '../utils/tanzil_text.dart';

class QuranAyah {
  const QuranAyah({
    required this.surah,
    required this.ayah,
    required this.textAr,
    required this.page,
    required this.juz,
    this.translation,
  });

  final int surah;
  final int ayah;
  final String textAr;
  final int page;
  final int juz;
  final String? translation;

  QuranAyah copyWith({String? translation}) {
    return QuranAyah(
      surah: surah,
      ayah: ayah,
      textAr: textAr,
      page: page,
      juz: juz,
      translation: translation ?? this.translation,
    );
  }

  factory QuranAyah.fromMap(Map<String, Object?> map) {
    return QuranAyah(
      surah: map['surah'] as int,
      ayah: map['ayah'] as int,
      textAr: normalizeTanzilTextForDisplay(map['text'] as String? ?? ''),
      page: map['page'] as int? ?? 1,
      juz: map['juz'] as int? ?? 1,
      translation: map['translation'] as String?,
    );
  }
}
