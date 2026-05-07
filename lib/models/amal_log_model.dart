import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/amal_fields.dart';

/// Builds [toggles] from flat Firestore/Hive keys. Takbir is clamped to fard
/// so old `takbir: true` with `fard: 3` does not become 5 > fard.
Map<String, dynamic> _togglesFromSource(Map<String, dynamic> src) {
  final fardField = kAmalFields.firstWhere((f) => f.id == 'fard');
  final takbirField = kAmalFields.firstWhere((f) => f.id == 'takbir');
  final fard = getNumericValue(src['fard'], fardField.maxValue);
  final takbir = getNumericValue(
    src['takbir'],
    takbirField.maxValue,
  ).clamp(0, fard);

  final toggles = <String, dynamic>{};
  for (final field in kAmalFields) {
    if (field.id == 'fard') {
      toggles[field.id] = fard;
    } else if (field.id == 'takbir') {
      toggles[field.id] = takbir;
    } else if (field.type == AmalType.numeric) {
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
  });

  final String uid;
  final String displayName;
  final String photoUrl;
  final bool isAnonymousDisplay;
  final String hijriDate;
  final Map<String, dynamic> toggles;
  final int score;
  final DateTime submittedAt;

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
      score: (data['score'] as num?)?.toInt() ?? calculateScore(toggles),
      submittedAt: submitted is Timestamp
          ? submitted.toDate()
          : DateTime.now(),
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
      score: (map['score'] as num?)?.toInt() ?? calculateScore(toggles),
      submittedAt: submittedMs is int
          ? DateTime.fromMillisecondsSinceEpoch(submittedMs, isUtc: true)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    final out = <String, dynamic>{
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAnonymousDisplay': isAnonymousDisplay,
      'hijriDate': hijriDate,
      'score': score,
      'submittedAt': Timestamp.fromDate(submittedAt.toUtc()),
    };
    for (final field in kAmalFields) {
      out[field.id] = toggles[field.id] ?? false;
    }
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
    };
  }
}
