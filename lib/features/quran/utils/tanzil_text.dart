/// Tanzil encodes a silent-letter hint as [U+06DF] after the base letter.
/// [UthmanicHafs] does not position U+06DF correctly (it appears as a stray
/// dot), but it renders [U+0670] superscript alef on the same letter.
final _tanzilRoundedZeroPattern = RegExp(
  r'([\u0621-\u064A\u0671\u0677\u06C0\u06C1\u06C2\u06D3\u06D5\u06FA\u06FF])۟',
);

/// Waqf/stop marks that [UthmanicHafs] draws as stray symbols.
///
/// [U+0670], [U+06E5], and [U+06E6] are excluded — valid Uthmani diacritics.
final _tanzilWaqfMarksPattern = RegExp(
  r'[\u0610-\u0615\u06D6-\u06DC\u06DE\u06E0-\u06E4\u06E7-\u06ED]',
);

/// Prepares Tanzil Uthmani text for display with [UthmanicHafs].
String normalizeTanzilTextForDisplay(String text) {
  if (text.isEmpty) return text;

  final withSuperscriptAlef = text.replaceAllMapped(
    _tanzilRoundedZeroPattern,
    (match) => '${match.group(1)!}\u0670',
  );

  return withSuperscriptAlef.replaceAll(_tanzilWaqfMarksPattern, '');
}
