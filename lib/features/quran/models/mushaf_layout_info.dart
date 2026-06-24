class MushafLayoutInfo {
  const MushafLayoutInfo({
    required this.name,
    required this.pageCount,
    required this.linesPerPage,
    required this.fontName,
  });

  final String name;
  final int pageCount;
  final int linesPerPage;
  final String fontName;

  factory MushafLayoutInfo.fromMap(Map<String, Object?> map) {
    return MushafLayoutInfo(
      name: map['name'] as String? ?? '',
      pageCount: parseMushafInt(map['number_of_pages']) ?? 610,
      linesPerPage: parseMushafInt(map['lines_per_page']) ?? 15,
      fontName: map['font_name'] as String? ?? 'qpc-nastaleeq',
    );
  }
}

int? parseMushafInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
  if (value is num) return value.toInt();
  return null;
}

bool _asBool(Object? value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return trimmed == '1' || trimmed.toLowerCase() == 'true';
  }
  return false;
}

class MushafLineRow {
  const MushafLineRow({
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    this.firstWordId,
    this.lastWordId,
    this.surahNumber,
  });

  final int pageNumber;
  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final int? firstWordId;
  final int? lastWordId;
  final int? surahNumber;

  factory MushafLineRow.fromMap(Map<String, Object?> map) {
    return MushafLineRow(
      pageNumber: parseMushafInt(map['page_number']) ?? 0,
      lineNumber: parseMushafInt(map['line_number']) ?? 0,
      lineType: map['line_type'] as String? ?? 'ayah',
      isCentered: _asBool(map['is_centered']),
      firstWordId: parseMushafInt(map['first_word_id']),
      lastWordId: parseMushafInt(map['last_word_id']),
      surahNumber: parseMushafInt(map['surah_number']),
    );
  }
}

class MushafWord {
  const MushafWord({
    required this.id,
    required this.location,
    required this.surah,
    required this.ayah,
    required this.word,
    required this.text,
  });

  final int id;
  final String location;
  final int surah;
  final int ayah;
  final int word;
  final String text;

  factory MushafWord.fromMap(Map<String, Object?> map) {
    return MushafWord(
      id: parseMushafInt(map['id']) ?? 0,
      location: map['location'] as String? ?? '',
      surah: parseMushafInt(map['surah']) ?? 0,
      ayah: parseMushafInt(map['ayah']) ?? 0,
      word: parseMushafInt(map['word']) ?? 0,
      text: map['text'] as String? ?? '',
    );
  }
}

/// A single rendered line on a mushaf page.
class MushafRenderedLine {
  const MushafRenderedLine({
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    required this.text,
    this.surahNumber,
    this.segments = const [],
  });

  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final String text;
  final int? surahNumber;
  final List<MushafLineSegment> segments;

  bool get isSurahName => lineType == 'surah_name';
  bool get isBasmallah => lineType == 'basmallah';
}

/// One word or ayah-end marker segment within a mushaf line.
class MushafLineSegment {
  const MushafLineSegment({
    required this.text,
    this.leadingSpace = false,
    this.isAyahEnd = false,
  });

  final String text;
  final bool leadingSpace;
  final bool isAyahEnd;
}

final _arabicIndicDigitPattern = RegExp(r'^[٠-٩]+$');

/// Ornate ayah-end frames in QPC mushaf databases (Arabic Presentation Forms-A
/// and legacy PUA slots used by QPC Nastaleeq).
final _qpcOrnamentPattern = RegExp(r'[\uFD30-\uFDF5\uF600-\uF6FF]');

bool isMushafAyahEndMarkerText(String text) {
  if (text.isEmpty) return false;
  if (_qpcOrnamentPattern.hasMatch(text)) return true;
  return _arabicIndicDigitPattern.hasMatch(text);
}

List<MushafLineSegment> buildMushafLineSegments(List<MushafWord> words) {
  if (words.isEmpty) return const [];

  final segments = <MushafLineSegment>[];
  for (final word in words) {
    final text = word.text;
    if (text.isEmpty) continue;

    final isAyahEnd = isMushafAyahEndMarkerText(text);

    segments.add(
      MushafLineSegment(
        text: text,
        leadingSpace: segments.isNotEmpty && !isAyahEnd,
        isAyahEnd: isAyahEnd,
      ),
    );
  }
  return segments;
}

String mushafSegmentsToPlainText(List<MushafLineSegment> segments) {
  final buffer = StringBuffer();
  for (final segment in segments) {
    if (segment.leadingSpace && buffer.isNotEmpty) buffer.write(' ');
    buffer.write(segment.text);
  }
  return buffer.toString();
}

/// Surah + ayah reference on a mushaf page.
class MushafAyahKey {
  const MushafAyahKey({required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MushafAyahKey && surah == other.surah && ayah == other.ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);
}
