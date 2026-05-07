enum AmalType { boolean, numeric }

class AmalField {
  final String id;
  final String label;
  final String labelBn;
  final String sublabel;
  final int points;
  final int maxValue;
  final AmalType type;

  const AmalField({
    required this.id,
    required this.label,
    required this.labelBn,
    required this.sublabel,
    required this.points,
    this.maxValue = 1,
    this.type = AmalType.boolean,
  });
}

const List<AmalField> kAmalFields = [
  AmalField(
    id: 'fard',
    label: 'Fard Salah',
    labelBn: 'জামাতে ফরয নামাজ',
    sublabel: 'জামাতে মোট ফরয নামাজ আদায়',
    points: 30,
    maxValue: 5,
    type: AmalType.numeric,
  ),
  AmalField(
    id: 'takbir',
    label: 'Takbir-e-Ula',
    labelBn: 'তাকবীরে উলা',
    sublabel: 'তাকবীরে উলার সাথে জামাতে মোট ফরয নামাজ',
    points: 10,
    maxValue: 5,
    type: AmalType.numeric,
  ),
  AmalField(
    id: 'morning_azkar',
    label: 'Morning Azkar',
    labelBn: 'সকালের আযকার',
    sublabel: 'সকালের আযকার সম্পন্ন',
    points: 10,
  ),
  AmalField(
    id: 'evening_azkar',
    label: 'Evening Azkar',
    labelBn: 'সন্ধ্যার আযকার',
    sublabel: 'সন্ধ্যার আযকার সম্পন্ন',
    points: 10,
  ),
  AmalField(
    id: 'quran',
    label: 'Quran Tilawat',
    labelBn: 'কুরআন তিলাওয়াত',
    sublabel: 'কমপক্ষে এক রুকু তিলাওয়াত',
    points: 10,
  ),
  AmalField(
    id: 'mulk',
    label: 'Surah Mulk',
    labelBn: 'সূরা মূলক',
    sublabel: 'রাতে ঘুমের আগে সূরা মূলক তিলাওয়াত',
    points: 10,
  ),
  AmalField(
    id: 'miswak',
    label: 'Miswak',
    labelBn: 'মিসওয়াক',
    sublabel: 'ওজুতে মিসওয়াক (কমপক্ষে দিনে একবার)',
    points: 5,
  ),
  AmalField(
    id: 'sunnah',
    label: 'Sunnah + Witr',
    labelBn: 'সুন্নাহ + বিতির',
    sublabel: 'ফরয নামাজ ব্যতীত ১২ রাকাত সুন্নাহ + বিতির',
    points: 10,
  ),
  AmalField(
    id: 'post_azkar',
    label: 'Post-prayer Azkar',
    labelBn: 'নামাজ পরবর্তী আযকার',
    sublabel: 'ফরয নামাজ পরবর্তী আযকার সম্পন্ন',
    points: 5,
  ),
];

const int kMaxDailyScore = 100;

int getNumericValue(dynamic rawValue, int maxValue) {
  if (rawValue == null) return 0;
  if (rawValue is bool) return rawValue ? maxValue : 0;
  if (rawValue is num) return rawValue.toInt().clamp(0, maxValue);
  return 0;
}

int calculateScore(Map<String, dynamic> log) {
  int score = 0;
  for (final field in kAmalFields) {
    if (field.type == AmalType.boolean) {
      if (log[field.id] == true) {
        score += field.points;
      }
    } else {
      final val = getNumericValue(log[field.id], field.maxValue);
      score += ((val / field.maxValue) * field.points).round();
    }
  }
  return score.clamp(0, kMaxDailyScore);
}
