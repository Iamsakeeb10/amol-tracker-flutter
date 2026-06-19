class QuranConstants {
  QuranConstants._();

  static const arabicFontFamily = 'DigitalKhattIndopak';
  static const totalPages = 604;
  static const totalSurahs = 114;

  static const translatorKhan = 'khan';
  static const translatorSahih = 'sahih';

  static const defaultQariId = 'Alafasy_128kbps';
  static const everyAyahBaseUrl = 'https://everyayah.com/data';

  static const qaris = <QuranQari>[
    QuranQari(
      id: 'Alafasy_128kbps',
      nameEn: 'Mishary Rashid Alafasy',
      nameBn: 'মিশারী রশিদ আলআফাসি',
    ),
    QuranQari(
      id: 'Abdul_Basit_Murattal_192kbps',
      nameEn: 'Abdul Basit (Murattal)',
      nameBn: 'আব্দুল বাসিত (মুরাত্তাল)',
    ),
    QuranQari(
      id: 'Husary_128kbps',
      nameEn: 'Mahmoud Al-Husary',
      nameBn: 'মাহমুদ আল-হুসারি',
    ),
    QuranQari(
      id: 'Ghamdi_40kbps',
      nameEn: 'Saad Al-Ghamdi',
      nameBn: 'সাদ আল-গামদি',
    ),
    QuranQari(
      id: 'Minshawy_Murattal_128kbps',
      nameEn: 'Minshawi (Murattal)',
      nameBn: 'মিনশাওই (মুরাত্তাল)',
    ),
  ];

  static QuranQari qariById(String id) {
    return qaris.firstWhere(
      (q) => q.id == id,
      orElse: () => qaris.first,
    );
  }

  static String everyAyahUrl({
    required String qariId,
    required int surah,
    required int ayah,
  }) {
    final surahPart = surah.toString().padLeft(3, '0');
    final ayahPart = ayah.toString().padLeft(3, '0');
    return '$everyAyahBaseUrl/$qariId/$surahPart$ayahPart.mp3';
  }
}

class QuranQari {
  const QuranQari({
    required this.id,
    required this.nameEn,
    required this.nameBn,
  });

  final String id;
  final String nameEn;
  final String nameBn;
}
