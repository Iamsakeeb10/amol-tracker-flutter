import '../l10n/app_localizations.dart';

const kSubhanAllahId = 'subhan_allah';
const kAlhamdulillahId = 'alhamdulillah';
const kAllahuAkbarId = 'allahu_akbar';

/// Built-in tasbeeh presets after salah.
const kBuiltInDhikrPresets = <DhikrPreset>[
  DhikrPreset(
    id: kSubhanAllahId,
    arabicName: 'سُبْحَانَ اللَّهِ',
    target: 33,
  ),
  DhikrPreset(
    id: kAlhamdulillahId,
    arabicName: 'الْحَمْدُ لِلَّهِ',
    target: 33,
  ),
  DhikrPreset(
    id: kAllahuAkbarId,
    arabicName: 'اللَّهُ أَكْبَرُ',
    target: 34,
  ),
];

class DhikrPreset {
  const DhikrPreset({
    required this.id,
    required this.target,
    this.arabicName,
    this.customName,
    this.isCustom = false,
  });

  final String id;
  final int target;
  final String? arabicName;
  final String? customName;
  final bool isCustom;

  String displayName(AppLocalizations l10n) {
    if (isCustom) return customName ?? '';
    switch (id) {
      case kSubhanAllahId:
        return l10n.subhanAllah;
      case kAlhamdulillahId:
        return l10n.alhamdulillah;
      case kAllahuAkbarId:
        return l10n.allahuAkbar;
      default:
        return customName ?? id;
    }
  }

  factory DhikrPreset.fromMap(Map<String, dynamic> map) {
    final isCustom = map['isCustom'] == true;
    return DhikrPreset(
      id: map['id'] as String? ?? '',
      target: (map['target'] as num?)?.toInt() ?? 33,
      arabicName: map['arabicName'] as String?,
      customName: map['customName'] as String?,
      isCustom: isCustom,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'target': target,
      if (arabicName != null) 'arabicName': arabicName,
      if (customName != null) 'customName': customName,
      'isCustom': isCustom,
    };
  }

  DhikrPreset copyWith({
    String? id,
    int? target,
    String? arabicName,
    String? customName,
    bool? isCustom,
  }) {
    return DhikrPreset(
      id: id ?? this.id,
      target: target ?? this.target,
      arabicName: arabicName ?? this.arabicName,
      customName: customName ?? this.customName,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

class DhikrSession {
  const DhikrSession({
    required this.presetId,
    required this.name,
    required this.target,
    required this.completedAt,
    required this.hijriDate,
  });

  final String presetId;
  final String name;
  final int target;
  final DateTime completedAt;
  final String hijriDate;

  factory DhikrSession.fromMap(Map<String, dynamic> map) {
    final completedMs = map['completedAtMs'];
    return DhikrSession(
      presetId: map['presetId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      target: (map['target'] as num?)?.toInt() ?? 0,
      completedAt: completedMs is int
          ? DateTime.fromMillisecondsSinceEpoch(completedMs, isUtc: true)
          : DateTime.now().toUtc(),
      hijriDate: map['hijriDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'presetId': presetId,
      'name': name,
      'target': target,
      'completedAtMs': completedAt.toUtc().millisecondsSinceEpoch,
      'hijriDate': hijriDate,
    };
  }
}
