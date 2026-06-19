/// One ayah row from the Indopak Nastaleeq SQLite edition.
///
/// Schema from [fonts.quran.ws](https://fonts.quran.ws/usage):
/// `ayat(surah, ayah, text, page, juz)` with primary key `(surah, ayah)`.
class QuranAyah {
  const QuranAyah({
    required this.surah,
    required this.ayah,
    required this.text,
    this.page,
    this.juz,
  });

  final int surah;
  final int ayah;
  final String text;
  final int? page;
  final int? juz;

  factory QuranAyah.fromMap(Map<String, Object?> map) {
    return QuranAyah(
      surah: map['surah']! as int,
      ayah: map['ayah']! as int,
      text: map['text']! as String,
      page: map['page'] as int?,
      juz: map['juz'] as int?,
    );
  }
}
