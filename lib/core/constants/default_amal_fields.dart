import 'amal_fields.dart';

/// UI cap when Firestore max score exceeds 100 (misconfiguration guard).
const int kDefaultMaxDailyScore = 100;

int _amalFieldSortOrder(AmalField a, AmalField b) {
  final orderCompare = a.order.compareTo(b.order);
  if (orderCompare != 0) return orderCompare;
  return a.id.compareTo(b.id);
}

/// Active Firestore fields with valid ids, sorted by [AmalField.order].
List<AmalField> activeAmalFields(List<AmalField> fields) {
  final active = fields.where((f) => f.isActive && f.id.isNotEmpty).toList();
  active.sort(_amalFieldSortOrder);
  return active;
}

/// Alias for [activeAmalFields] — provider already returns Firestore-only data.
List<AmalField> resolveAmalFields(List<AmalField> fields) =>
    activeAmalFields(fields);

/// Bundled fallback when Hive cache and Firestore are both unavailable.
const List<AmalField> kDefaultAmalFields = [
  AmalField(
    id: 'fard_salah',
    label: {'en': 'Fard Salah', 'bn': 'ফরয নামাজ'},
    sublabel: {
      'en': 'Total fard prayers performed today',
      'bn': 'আজ মোট কত ওয়াক্ত ফরয নামাজ আদায় করেছেন',
    },
    points: 10,
    maxValue: 5,
    type: AmalType.numeric,
    order: 1,
  ),
  AmalField(
    id: 'fard',
    label: {'en': "Jama'at Fard Salah", 'bn': 'জামাতে ফরয নামাজ'},
    sublabel: {
      'en': "Total fard prayers performed in Jama'at today",
      'bn': 'আজ মোট কত ওয়াক্ত জামাতে ফরয নামাজ আদায় করেছেন',
    },
    points: 20,
    maxValue: 5,
    type: AmalType.numeric,
    order: 2,
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
    order: 3,
  ),
  AmalField(
    id: 'morning_azkar',
    label: {'en': 'Morning Azkar', 'bn': 'সকালের আযকার'},
    sublabel: {'en': 'Morning azkar completed', 'bn': 'সকালের আযকার সম্পন্ন'},
    points: 10,
    order: 4,
  ),
  AmalField(
    id: 'evening_azkar',
    label: {'en': 'Evening Azkar', 'bn': 'সন্ধ্যার আযকার'},
    sublabel: {'en': 'Evening azkar completed', 'bn': 'সন্ধ্যার আযকার সম্পন্ন'},
    points: 10,
    order: 5,
  ),
  AmalField(
    id: 'quran',
    label: {'en': 'Quran Tilawat', 'bn': 'কুরআন তিলাওয়াত'},
    sublabel: {
      'en': 'At least one ruku of recitation',
      'bn': 'কমপক্ষে এক রুকু তিলাওয়াত',
    },
    points: 10,
    order: 6,
  ),
  AmalField(
    id: 'mulk',
    label: {'en': 'Surah Mulk', 'bn': 'সূরা মূলক'},
    sublabel: {
      'en': 'Surah Mulk before sleep',
      'bn': 'রাতে ঘুমের আগে সূরা মূলক তিলাওয়াত',
    },
    points: 10,
    order: 7,
  ),
  AmalField(
    id: 'miswak',
    label: {'en': 'Miswak', 'bn': 'মিসওয়াক'},
    sublabel: {
      'en': 'Miswak with wudu (at least once daily)',
      'bn': 'ওজুতে মিসওয়াক (কমপক্ষে দিনে একবার)',
    },
    points: 5,
    order: 8,
  ),
  AmalField(
    id: 'sunnah',
    label: {'en': 'Sunnah + Witr', 'bn': 'সুন্নাহ + বিতির'},
    sublabel: {
      'en': '12 rakah sunnah + witr besides fard',
      'bn': 'ফরয নামাজ ব্যতীত ১২ রাকাত সুন্নাহ + বিতির',
    },
    points: 10,
    order: 9,
  ),
  AmalField(
    id: 'post_azkar',
    label: {'en': 'Post-prayer Azkar', 'bn': 'নামাজ পরবর্তী আযকার'},
    sublabel: {
      'en': 'Azkar after fard prayers',
      'bn': 'ফরয নামাজ পরবর্তী আযকার সম্পন্ন',
    },
    points: 5,
    order: 10,
  ),
];
