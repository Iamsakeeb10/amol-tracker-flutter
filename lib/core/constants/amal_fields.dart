import 'package:cloud_firestore/cloud_firestore.dart';

enum AmalType { boolean, numeric }

enum IconSource { fontAwesome, material }

enum GenderVisibility { all, maleOnly, femaleOnly }

class AmalField {
  final String id;
  final Map<String, String> label;
  final Map<String, String> sublabel;
  final int points;
  final int maxValue;
  final AmalType type;
  final int order;
  final bool isActive;
  final String? iconName;
  final IconSource? iconSource;
  final DateTime? createdAt;

  final bool expandable;

  final GenderVisibility genderVisibility;
  final bool femaleDeprioritized;
  final bool disableDuringSpecialTime;

  const AmalField({
    required this.id,
    required this.label,
    required this.sublabel,
    required this.points,
    this.maxValue = 1,
    this.type = AmalType.boolean,
    this.order = 999,
    this.isActive = true,
    this.iconName,
    this.iconSource,
    this.createdAt,
    this.expandable = false,
    this.genderVisibility = GenderVisibility.all,
    this.femaleDeprioritized = false,
    this.disableDuringSpecialTime = false,
  });

  bool get supportsExpansion =>
      expandable && type == AmalType.numeric && maxValue == 5;

  String getLabel(String locale) {
    final key = locale == 'bn' ? 'bn' : 'en';
    final value = label[key]?.trim();
    if (value != null && value.isNotEmpty) return value;
    return label['en']?.trim() ?? '';
  }

  String getSublabel(String locale) {
    final key = locale == 'bn' ? 'bn' : 'en';
    final value = sublabel[key]?.trim();
    if (value != null && value.isNotEmpty) return value;
    return sublabel['en']?.trim() ?? '';
  }

  factory AmalField.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AmalField.fromMap(<String, dynamic>{
      ...data,
      'id': (data['id'] as String?)?.trim().isNotEmpty == true
          ? data['id']
          : doc.id,
    });
  }

  factory AmalField.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] as String?)?.trim() ?? '';
    DateTime? createdAt;
    final raw = map['createdAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else if (raw is DateTime) {
      createdAt = raw;
    }
    return AmalField(
      id: id,
      label: _parseLocaleMap(map['label']),
      sublabel: _parseLocaleMap(map['sublabel']),
      points: (map['points'] as num?)?.toInt() ?? 0,
      maxValue: (map['maxValue'] as num?)?.toInt() ?? 1,
      type: _parseType(map['type']),
      order: (map['order'] as num?)?.toInt() ?? 999,
      isActive: parseIsActive(map['isActive']),
      iconName: (map['iconName'] as String?)?.trim(),
      iconSource: _parseIconSource(map['iconSource']),
      createdAt: createdAt,
      expandable: _parseBool(map['expandable']),
      genderVisibility: _parseGenderVisibility(map['genderVisibility']),
      femaleDeprioritized: _parseBool(map['femaleDeprioritized']),
      disableDuringSpecialTime: _parseBool(map['disableDuringSpecialTime']),
    );
  }

  static bool parseIsActive(dynamic raw) {
    if (raw == null) return true;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final v = raw.trim().toLowerCase();
      if (v == 'false' || v == '0' || v == 'no') return false;
      if (v == 'true' || v == '1' || v == 'yes') return true;
    }
    return true;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'label': Map<String, String>.from(label),
      'sublabel': Map<String, String>.from(sublabel),
      'points': points,
      'maxValue': maxValue,
      'type': type == AmalType.numeric ? 'numeric' : 'boolean',
      'order': order,
      'isActive': isActive,
      'expandable': expandable,
      'genderVisibility': _genderVisibilityToString(genderVisibility),
      'femaleDeprioritized': femaleDeprioritized,
      'disableDuringSpecialTime': disableDuringSpecialTime,
      if (iconName != null) 'iconName': iconName,
      if (iconSource != null) 'iconSource': iconSource == IconSource.material ? 'material' : 'fontAwesome',
    };
  }

  static Map<String, String> _parseLocaleMap(dynamic raw) {
    if (raw is! Map) return const <String, String>{};
    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  static AmalType _parseType(dynamic raw) {
    if (raw == 'numeric' || raw == AmalType.numeric.name) {
      return AmalType.numeric;
    }
    return AmalType.boolean;
  }

  static IconSource? _parseIconSource(dynamic raw) {
    if (raw == 'material') return IconSource.material;
    if (raw == 'fontAwesome') return IconSource.fontAwesome;
    return null;
  }

  static bool _parseBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final v = raw.trim().toLowerCase();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }

  static GenderVisibility _parseGenderVisibility(dynamic raw) {
    if (raw == null) return GenderVisibility.all;
    final value = raw.toString().trim().toLowerCase();
    if (value == 'male_only') return GenderVisibility.maleOnly;
    if (value == 'female_only') return GenderVisibility.femaleOnly;
    return GenderVisibility.all;
  }

  static String _genderVisibilityToString(GenderVisibility value) {
    switch (value) {
      case GenderVisibility.maleOnly:
        return 'male_only';
      case GenderVisibility.femaleOnly:
        return 'female_only';
      case GenderVisibility.all:
        return 'all';
    }
  }
}
