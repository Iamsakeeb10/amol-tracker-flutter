/// Key Islamic calendar occasions keyed by Hijri month and day.
class HijriEvents {
  HijriEvents._();

  static const List<HijriEventEntry> all = [
    HijriEventEntry(month: 1, day: 1, id: HijriEventId.islamicNewYear),
    HijriEventEntry(month: 1, day: 10, id: HijriEventId.ashura),
    HijriEventEntry(month: 3, day: 12, id: HijriEventId.mawlid),
    HijriEventEntry(month: 7, day: 27, id: HijriEventId.israMiraj),
    HijriEventEntry(month: 8, day: 15, id: HijriEventId.shabeBarat),
    HijriEventEntry(month: 9, day: 1, id: HijriEventId.ramadanStart),
    HijriEventEntry(month: 9, day: 27, id: HijriEventId.laylatAlQadr),
    HijriEventEntry(month: 10, day: 1, id: HijriEventId.eidAlFitr),
    HijriEventEntry(month: 12, day: 9, id: HijriEventId.arafat),
    HijriEventEntry(month: 12, day: 10, id: HijriEventId.eidAlAdha),
  ];

  static bool hasEvent(int hijriMonth, int hijriDay) {
    return all.any((e) => e.month == hijriMonth && e.day == hijriDay);
  }

  static List<HijriEventEntry> forMonth(int hijriMonth) {
    return all.where((e) => e.month == hijriMonth).toList()
      ..sort((a, b) => a.day.compareTo(b.day));
  }
}

enum HijriEventId {
  islamicNewYear,
  ashura,
  mawlid,
  israMiraj,
  shabeBarat,
  ramadanStart,
  laylatAlQadr,
  eidAlFitr,
  arafat,
  eidAlAdha,
}

class HijriEventEntry {
  const HijriEventEntry({
    required this.month,
    required this.day,
    required this.id,
  });

  final int month;
  final int day;
  final HijriEventId id;
}
