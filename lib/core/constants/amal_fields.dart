import 'package:cloud_firestore/cloud_firestore.dart';

enum AmalType { boolean, numeric }

class AmalField {
  final String id;
  final Map<String, String> label;
  final Map<String, String> sublabel;
  final int points;
  final int maxValue;
  final AmalType type;
  final int order;
  final bool isActive;

  const AmalField({
    required this.id,
    required this.label,
    required this.sublabel,
    required this.points,
    this.maxValue = 1,
    this.type = AmalType.boolean,
    this.order = 999,
    this.isActive = true,
  });

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
    return AmalField(
      id: id,
      label: _parseLocaleMap(map['label']),
      sublabel: _parseLocaleMap(map['sublabel']),
      points: (map['points'] as num?)?.toInt() ?? 0,
      maxValue: (map['maxValue'] as num?)?.toInt() ?? 1,
      type: _parseType(map['type']),
      order: (map['order'] as num?)?.toInt() ?? 999,
      isActive: parseIsActive(map['isActive']),
    );
  }

  /// Firestore/console may store booleans as strings; missing field = active.
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
}
