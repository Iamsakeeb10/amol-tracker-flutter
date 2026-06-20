import 'mushaf_layout_info.dart';

/// Line-based mushaf page content (QPC Nastaleeq 15-line layout).
class QuranMushafPageData {
  const QuranMushafPageData({
    required this.page,
    required this.juz,
    required this.linesPerPage,
    required this.lines,
  });

  final int page;
  final int juz;
  final int linesPerPage;
  final List<MushafRenderedLine> lines;
}
