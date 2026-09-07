import 'package:cloud_firestore/cloud_firestore.dart';

// Personal amol is stored in a per-user subcollection. It is never queried
// cross-user and must never appear in community score, streak, or leaderboard
// calculations. Any such merge (e.g. history calendar display) is input-only
// for the user's own view and must be separated back out before reuse.

enum PersonalAmolFrequency {
  daily,
  weekdays;

  static PersonalAmolFrequency fromMap(dynamic value) {
    if (value is String && value == 'weekdays') return PersonalAmolFrequency.weekdays;
    return PersonalAmolFrequency.daily;
  }
}

enum PersonalAmolType {
  /// A single on/off completion per day (switch).
  toggle,
  /// A counted habit with a daily target (greater-than-one increments).
  count;

  static PersonalAmolType fromMap(dynamic value) {
    if (value is String && value == 'count') return PersonalAmolType.count;
    return PersonalAmolType.toggle;
  }
}

class PersonalAmolModel {
  const PersonalAmolModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.frequency,
    required this.weekdays,
    required this.reminderTime,
    required this.isActive,
    required this.createdAt,
    this.type = PersonalAmolType.toggle,
    this.target = 1,
  });

  final String id;
  final String name;

  /// Either an emoji string (legacy, max 2 grapheme clusters) or a Material
  /// icon token persisted via `encodePersonalAmolIcon` (e.g. `m:auto_awesome`).
  final String icon;
  final PersonalAmolFrequency frequency;

  /// 1-based weekday indices (1 = Saturday ... 7 = Friday) used when
  /// [frequency] is [PersonalAmolFrequency.weekdays]. Empty otherwise.
  final List<int> weekdays;

  /// Serialized as `{hour, minute}` in Firestore. Null means no reminder.
  final ({int hour, int minute})? reminderTime;
  final bool isActive;
  final DateTime createdAt;

  /// Tracking style. [PersonalAmolType.count] amols log progress towards
  /// [target] with +/− increments.
  final PersonalAmolType type;

  /// Daily target for [PersonalAmolType.count] amols. Always 1 for toggle.
  final int target;

  PersonalAmolModel copyWith({
    String? name,
    String? icon,
    PersonalAmolFrequency? frequency,
    List<int>? weekdays,
    ({int hour, int minute})? reminderTime,
    bool? isActive,
    PersonalAmolType? type,
    int? target,
  }) {
    return PersonalAmolModel(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      type: type ?? this.type,
      target: target ?? this.target,
    );
  }

  factory PersonalAmolModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return PersonalAmolModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      icon: (data['icon'] as String?) ?? '',
      frequency: PersonalAmolFrequency.fromMap(data['frequency']),
      weekdays: _weekdaysFromMap(data['weekdays']),
      reminderTime: _timeFromMap(data['reminderTime']),
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: _createdAtFromMap(data['createdAt']),
      type: PersonalAmolType.fromMap(data['type']),
      target: _targetFromMap(data['target']),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'icon': icon,
      'frequency': frequency == PersonalAmolFrequency.weekdays ? 'weekdays' : 'daily',
      'weekdays': weekdays,
      'reminderTime': reminderTime == null
          ? null
          : {'hour': reminderTime!.hour, 'minute': reminderTime!.minute},
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type == PersonalAmolType.count ? 'count' : 'toggle',
      'target': target,
    };
  }

  static List<int> _weekdaysFromMap(dynamic value) {
    if (value is List) {
      return value.map((e) => (e as num).toInt()).where((d) => d >= 1 && d <= 7).toList();
    }
    return const <int>[];
  }

  static int _targetFromMap(dynamic value) {
    if (value is num && value.toInt() >= 1) return value.toInt();
    return 1;
  }

  static ({int hour, int minute})? _timeFromMap(dynamic value) {
    if (value is Map) {
      final hour = value['hour'];
      final minute = value['minute'];
      if (hour is num && minute is num) {
        return (hour: hour.toInt(), minute: minute.toInt());
      }
    }
    return null;
  }

  static DateTime _createdAtFromMap(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

class PersonalAmolCompletion {
  const PersonalAmolCompletion({
    required this.amolId,
    required this.hijriDate,
    required this.completedAt,
  });

  final String amolId;

  /// Hijri storage key `YYYY-MM-DD`.
  final String hijriDate;
  final DateTime completedAt;

  factory PersonalAmolCompletion.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PersonalAmolCompletion(
      amolId: (data['amolId'] as String?) ?? '',
      hijriDate: (data['hijriDate'] as String?) ?? '',
      completedAt: (data['completedAt'] is Timestamp)
          ? (data['completedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'amolId': amolId,
      'hijriDate': hijriDate,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }
}
