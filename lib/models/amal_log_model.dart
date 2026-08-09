import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/amal_fields.dart';
import '../core/utils/score_calculator.dart';

const _logMetadataKeys = <String>{
  'uid',
  'displayName',
  'photoUrl',
  'isAnonymousDisplay',
  'hijriDate',
  'score',
  'submittedAt',
  'submittedAtMs',
  'toggles',
  'editedAt',
  'editCount',
  'prayers',
  'maxScore',
  'activeFieldIds',
  'specialTimeApplied',
  'gender',
};

const List<String> kLegacyActiveFieldIds = [
  'fard_salah',
  'fard',
  'takbir',
  'morning_azkar',
  'evening_azkar',
  'quran',
  'mulk',
  'miswak',
  'sunnah',
  'post_azkar',
];

Map<String, dynamic> _togglesFromSource(Map<String, dynamic> src) {
  final togglesRaw = src['toggles'];
  final Map<String, dynamic> raw = togglesRaw is Map
      ? Map<String, dynamic>.from(togglesRaw.cast<dynamic, dynamic>())
      : Map<String, dynamic>.from(src)
        ..removeWhere((key, _) => _logMetadataKeys.contains(key));

  final toggles = <String, dynamic>{};
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is bool) {
      toggles[entry.key] = value;
    } else if (value is num) {
      toggles[entry.key] = value.toInt();
    } else {
      toggles[entry.key] = value == true;
    }
  }
  return toggles;
}

/// Parses the `prayers` map stored in Firestore or Hive.
///
/// Expected format: `{ "fard_salah": [0, 2, 4], "fard": [2, 4] }`.
/// Returns an empty map if the field is absent or malformed (backward-compat
/// with logs created before prayer tracking was added).
Map<String, List<int>> _parsePrayers(dynamic raw) {
  if (raw is! Map) return const <String, List<int>>{};
  final result = <String, List<int>>{};
  raw.forEach((key, value) {
    if (value is List) {
      result[key.toString()] = value
          .map((e) => (e as num?)?.toInt())
          .whereType<int>()
          .toList();
    }
  });
  return result;
}

/// Parses the `activeFieldIds` list stored in Firestore or Hive.
/// Falls back to [kLegacyActiveFieldIds] when absent or malformed.
List<String> _parseActiveFieldIds(dynamic raw) {
  if (raw is List) {
    final ids = raw.map((e) => e.toString()).toList();
    if (ids.isNotEmpty) return ids;
  }
  return List<String>.from(kLegacyActiveFieldIds);
}

Map<String, dynamic> normalizeTogglesForFields(
  Map<String, dynamic> src,
  List<AmalField> fields,
) {
  final toggles = <String, dynamic>{};
  for (final field in fields) {
    if (field.type == AmalType.numeric) {
      toggles[field.id] = getNumericValue(src[field.id], field.maxValue);
    } else {
      toggles[field.id] = src[field.id] as bool? ?? false;
    }
  }
  return toggles;
}

/// One submitted daily log, stored at `amal_logs/{uid}_{hijriDate}`.
class AmalLogModel {
  AmalLogModel({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.isAnonymousDisplay,
    required this.hijriDate,
    required this.toggles,
    required this.score,
    required this.submittedAt,
    this.editedAt,
    this.editCount = 0,
    this.prayers = const <String, List<int>>{},
    this.maxScore = 100,
    this.activeFieldIds = kLegacyActiveFieldIds,
    this.specialTimeApplied = false,
    this.gender,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
  final bool isAnonymousDisplay;
  final String hijriDate;
  final Map<String, dynamic> toggles;
  final int score;
  final DateTime submittedAt;
  final DateTime? editedAt;
  final int editCount;

  /// Per-field prayer-slot selections persisted to Firestore on submit.
  ///
  /// Maps expandable field id → sorted list of lit slot indices (0 = Fajr,
  /// 1 = Dhuhr, 2 = Asr, 3 = Maghrib, 4 = Isha).
  /// Empty for old logs that pre-date this feature.
  final Map<String, List<int>> prayers;

  /// Maximum achievable score for this log (policy-derived at submit time).
  /// Legacy logs default to 100.
  final int maxScore;

  /// IDs of the fields that were active (contributed to score) at submit time.
  /// Legacy logs default to all 10 default fields.
  final List<String> activeFieldIds;

  /// Whether special-time rules were active when this log was submitted.
  final bool specialTimeApplied;
  
  /// Gender of the user at the time of submission.
  final String? gender;

  String get docId => '${uid}_$hijriDate';

  factory AmalLogModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final toggles = _togglesFromSource(data);
    final submitted = data['submittedAt'];
    return AmalLogModel(
      uid: (data['uid'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      photoUrl: (data['photoUrl'] as String?) ?? '',
      isAnonymousDisplay: (data['isAnonymousDisplay'] as bool?) ?? false,
      hijriDate: (data['hijriDate'] as String?) ?? '',
      toggles: toggles,
      score: (data['score'] as num?)?.toInt() ?? 0,
      submittedAt: submitted is Timestamp
          ? submitted.toDate()
          : DateTime.now(),
      editedAt: data['editedAt'] is Timestamp
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      editCount: (data['editCount'] as num?)?.toInt() ?? 0,
      prayers: _parsePrayers(data['prayers']),
      maxScore: (data['maxScore'] as num?)?.toInt() ?? 100,
      activeFieldIds: _parseActiveFieldIds(data['activeFieldIds']),
      specialTimeApplied: (data['specialTimeApplied'] as bool?) ?? false,
      gender: data['gender'] as String?,
    );
  }

  factory AmalLogModel.fromHiveMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final togglesRaw = map['toggles'];
    final toggles = togglesRaw is Map
        ? _togglesFromSource(Map<String, dynamic>.from(togglesRaw))
        : _togglesFromSource(map);
    final submittedMs = map['submittedAtMs'];
    return AmalLogModel(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      isAnonymousDisplay: map['isAnonymousDisplay'] as bool? ?? false,
      hijriDate: map['hijriDate'] as String? ?? '',
      toggles: toggles,
      score: (map['score'] as num?)?.toInt() ?? 0,
      submittedAt: submittedMs is int
          ? DateTime.fromMillisecondsSinceEpoch(submittedMs, isUtc: true)
          : DateTime.now(),
      editedAt: map['editedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'] as int, isUtc: true)
          : null,
      editCount: (map['editCount'] as num?)?.toInt() ?? 0,
      prayers: _parsePrayers(map['prayers']),
      maxScore: (map['maxScore'] as num?)?.toInt() ?? 100,
      activeFieldIds: _parseActiveFieldIds(map['activeFieldIds']),
      specialTimeApplied: (map['specialTimeApplied'] as bool?) ?? false,
      gender: map['gender'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreMap(List<AmalField> fields) {
    final out = <String, dynamic>{
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAnonymousDisplay': isAnonymousDisplay,
      'hijriDate': hijriDate,
      'score': score,
      'submittedAt': Timestamp.fromDate(submittedAt.toUtc()),
    };
    for (final field in fields) {
      if (field.type == AmalType.numeric) {
        out[field.id] = getNumericValue(toggles[field.id], field.maxValue);
      } else {
        out[field.id] = toggles[field.id] == true;
      }
    }
    if (prayers.isNotEmpty) {
      out['prayers'] = <String, dynamic>{
        for (final e in prayers.entries) e.key: List<int>.from(e.value),
      };
    }
    out['maxScore'] = maxScore;
    out['activeFieldIds'] = List<String>.from(activeFieldIds);
    out['specialTimeApplied'] = specialTimeApplied;
    if (gender != null) out['gender'] = gender;
    return out;
  }

  Map<String, dynamic> toEditFirestoreMap(List<AmalField> fields) {
    final out = <String, dynamic>{
      'score': score,
      'editedAt': Timestamp.fromDate(DateTime.now().toUtc()),
      'editCount': FieldValue.increment(1),
    };
    for (final field in fields) {
      if (field.type == AmalType.numeric) {
        out[field.id] = getNumericValue(toggles[field.id], field.maxValue);
      } else {
        out[field.id] = toggles[field.id] == true;
      }
    }
    if (prayers.isNotEmpty) {
      out['prayers'] = <String, dynamic>{
        for (final e in prayers.entries) e.key: List<int>.from(e.value),
      };
    }
    out['maxScore'] = maxScore;
    out['activeFieldIds'] = List<String>.from(activeFieldIds);
    out['specialTimeApplied'] = specialTimeApplied;
    if (gender != null) out['gender'] = gender;
    return out;
  }

  Map<String, dynamic> toHiveMap() {
    return <String, dynamic>{
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAnonymousDisplay': isAnonymousDisplay,
      'hijriDate': hijriDate,
      'score': score,
      'submittedAtMs': submittedAt.toUtc().millisecondsSinceEpoch,
      'toggles': Map<String, dynamic>.from(toggles),
      if (editedAt != null)
        'editedAt': editedAt!.toUtc().millisecondsSinceEpoch,
      'editCount': editCount,
      if (prayers.isNotEmpty)
        'prayers': <String, dynamic>{
          for (final e in prayers.entries) e.key: List<int>.from(e.value),
        },
      'maxScore': maxScore,
      'activeFieldIds': List<String>.from(activeFieldIds),
      'specialTimeApplied': specialTimeApplied,
      if (gender != null) 'gender': gender,
    };
  }
}
