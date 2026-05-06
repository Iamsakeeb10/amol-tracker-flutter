class AmalField {
  final String id;
  final String label;
  final String sublabel;
  final int points;
  final bool isNumeric;

  const AmalField({
    required this.id,
    required this.label,
    required this.sublabel,
    required this.points,
    this.isNumeric = false,
  });
}

const List<AmalField> kAmalFields = [
  AmalField(
    id: 'fard',
    label: 'Fard prayers',
    sublabel: 'All 5 in congregation',
    points: 20,
    isNumeric: true,
  ),
  AmalField(
    id: 'takbir',
    label: 'Takbir-e-Ula',
    sublabel: 'With congregation',
    points: 5,
    isNumeric: true,
  ),
  AmalField(
    id: 'morning_azkar',
    label: 'Morning Azkar',
    sublabel: 'After Fajr',
    points: 8,
  ),
  AmalField(
    id: 'evening_azkar',
    label: 'Evening Azkar',
    sublabel: 'After Asr',
    points: 8,
  ),
  AmalField(
    id: 'quran',
    label: 'Quran Tilawat',
    sublabel: 'Any amount',
    points: 10,
  ),
  AmalField(
    id: 'mulk',
    label: 'Surah Mulk',
    sublabel: 'Full recitation',
    points: 10,
  ),
  AmalField(
    id: 'miswak',
    label: 'Miswak',
    sublabel: 'Before prayer',
    points: 5,
  ),
  AmalField(
    id: 'sunnah',
    label: 'Sunnah + Witr',
    sublabel: 'All sunnah prayers',
    points: 10,
  ),
  AmalField(
    id: 'post_azkar',
    label: 'Post-prayer Azkar',
    sublabel: 'After each fard',
    points: 10,
  ),
];

const int kMaxDailyScore = 100;

int calculateScore(Map<String, dynamic> log) {
  var score = 0;
  for (final field in kAmalFields) {
    if (log[field.id] == true) {
      score += field.points;
    }
  }
  return score.clamp(0, kMaxDailyScore);
}
