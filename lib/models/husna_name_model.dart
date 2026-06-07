import 'package:flutter/material.dart';

class HusnaName {
  const HusnaName({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    required this.meaningBn,
    required this.benefit,
  });

  final int number;
  final String arabic;
  final String transliteration;
  final String meaning;
  final String meaningBn;
  final String benefit;

  String localizedMeaning(String languageCode) =>
      languageCode == 'bn' ? meaningBn : meaning;

  String localizedMeaningFromLocale(Locale locale) =>
      localizedMeaning(locale.languageCode);

  factory HusnaName.fromMap(Map<String, dynamic> map) {
    return HusnaName(
      number: (map['number'] as num?)?.toInt() ?? 0,
      arabic: map['arabic'] as String? ?? '',
      transliteration: map['transliteration'] as String? ?? '',
      meaning: map['meaning'] as String? ?? '',
      meaningBn: map['meaningBn'] as String? ?? '',
      benefit: map['benefit'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'number': number,
      'arabic': arabic,
      'transliteration': transliteration,
      'meaning': meaning,
      'meaningBn': meaningBn,
      'benefit': benefit,
    };
  }
}
