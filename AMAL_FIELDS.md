import 'package:flutter/material.dart';

class AmalField {
  final String id;
  final String label;
  final String sublabel;
  final int points;
  final bool isNumeric;
  final IconData icon;

  const AmalField({
    required this.id,
    required this.label,
    required this.sublabel,
    required this.points,
    required this.icon,
    this.isNumeric = false,
  });
}

const List<AmalField> kAmalFields = [
  AmalField(
    id: 'fard',
    label: 'Fard prayers',
    sublabel: 'All 5 in congregation',
    points: 20,
    icon: Icons.circle_outlined,
    isNumeric: true,
  ),
  AmalField(
    id: 'takbir',
    label: 'Takbir-e-Ula',
    sublabel: 'With congregation',
    points: 5,
    icon: Icons.star_outline,
    isNumeric: true,
  ),
  AmalField(
    id: 'morning_azkar',
    label: 'Morning Azkar',
    sublabel: 'After Fajr',
    points: 8,
    icon: Icons.wb_sunny_outlined,
  ),
  AmalField(
    id: 'evening_azkar',
    label: 'Evening Azkar',
    sublabel: 'After Asr',
    points: 8,
    icon: Icons.nightlight_outlined,
  ),
  AmalField(
    id: 'quran',
    label: 'Quran Tilawat',
    sublabel: 'Any amount',
    points: 10,
    icon: Icons.menu_book_outlined,
  ),
  AmalField(
    id: 'mulk',
    label: 'Surah Mulk',
    sublabel: 'Full recitation',
    points: 10,
    icon: Icons.bookmark_outline,
  ),
  AmalField(
    id: 'miswak',
    label: 'Miswak',
    sublabel: 'Before prayer',
    points: 5,
    icon: Icons.cleaning_services_outlined,
  ),
  AmalField(
    id: 'sunnah',
    label: 'Sunnah + Witr',
    sublabel: 'All sunnah prayers',
    points: 10,
    icon: Icons.brightness_low_outlined,
  ),
  AmalField(
    id: 'post_azkar',
    label: 'Post-prayer Azkar',
    sublabel: 'After each fard',
    points: 10,
    icon: Icons.access_time_outlined,
  ),
];

// Max possible score = 20+5+8+8+10+10+5+10+10 = 86
// Fard is counted as 20 when all 5 are done
// Total max = 100 when perfectly adjusted
const int kMaxDailyScore = 100;

int calculateScore(Map<String, dynamic> log) {
  int score = 0;
  for (final field in kAmalFields) {
    final value = log[field.id];
    if (value == true) {
      score += field.points;
    }
  }
  return score.clamp(0, kMaxDailyScore);
}
