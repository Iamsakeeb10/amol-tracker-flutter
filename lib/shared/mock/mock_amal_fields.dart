import '../../core/constants/amal_fields.dart';

const List<AmalField> kMockAmalFields = [
  AmalField(
    id: 'fard',
    label: {'en': 'Fard Salah', 'bn': 'জামাতে ফরয নামাজ'},
    sublabel: {
      'en': 'All five fard in congregation',
      'bn': 'জামাতে মোট ফরয নামাজ আদায়',
    },
    points: 30,
    maxValue: 5,
    type: AmalType.numeric,
    order: 1,
  ),
  AmalField(
    id: 'takbir',
    label: {'en': 'Takbir-e-Ula', 'bn': 'তাকবীরে উলা'},
    sublabel: {
      'en': 'Fard with takbir-e-ula in congregation',
      'bn': 'তাকবীরে উলার সাথে জামাতে মোট ফরয নামাজ',
    },
    points: 10,
    maxValue: 5,
    type: AmalType.numeric,
    order: 2,
  ),
  AmalField(
    id: 'morning_azkar',
    label: {'en': 'Morning Azkar', 'bn': 'সকালের আযকার'},
    sublabel: {'en': 'Morning azkar completed', 'bn': 'সকালের আযকার সম্পন্ন'},
    points: 10,
    order: 3,
  ),
  AmalField(
    id: 'evening_azkar',
    label: {'en': 'Evening Azkar', 'bn': 'সন্ধ্যার আযকার'},
    sublabel: {'en': 'Evening azkar completed', 'bn': 'সন্ধ্যার আযকার সম্পন্ন'},
    points: 10,
    order: 4,
  ),
  AmalField(
    id: 'quran',
    label: {'en': 'Quran Tilawat', 'bn': 'কুরআন তিলাওয়াত'},
    sublabel: {
      'en': 'At least one ruku of recitation',
      'bn': 'কমপক্ষে এক রুকু তিলাওয়াত',
    },
    points: 10,
    order: 5,
  ),
  AmalField(
    id: 'mulk',
    label: {'en': 'Surah Mulk', 'bn': 'সূরা মূলক'},
    sublabel: {
      'en': 'Surah Mulk before sleep',
      'bn': 'রাতে ঘুমের আগে সূরা মূলক তিলাওয়াত',
    },
    points: 10,
    order: 6,
  ),
  AmalField(
    id: 'miswak',
    label: {'en': 'Miswak', 'bn': 'মিসওয়াক'},
    sublabel: {
      'en': 'Miswak with wudu (at least once daily)',
      'bn': 'ওজুতে মিসওয়াক (কমপক্ষে দিনে একবার)',
    },
    points: 5,
    order: 7,
  ),
  AmalField(
    id: 'sunnah',
    label: {'en': 'Sunnah + Witr', 'bn': 'সুন্নাহ + বিতির'},
    sublabel: {
      'en': '12 rakah sunnah + witr besides fard',
      'bn': 'ফরয নামাজ ব্যতীত ১২ রাকাত সুন্নাহ + বিতির',
    },
    points: 10,
    order: 8,
  ),
  AmalField(
    id: 'post_azkar',
    label: {'en': 'Post-prayer Azkar', 'bn': 'নামাজ পরবর্তী আযকার'},
    sublabel: {
      'en': 'Azkar after fard prayers',
      'bn': 'ফরয নামাজ পরবর্তী আযকার সম্পন্ন',
    },
    points: 5,
    order: 9,
  ),
];

const int kMockMaxDailyScore = 100;
