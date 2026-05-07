import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final DateTime createdAt;
  final int currentStreak;
  final int bestStreak;
  final bool streakFreezeUsed;
  final String streakFreezeWeekKey;
  final String lastLogDate;
  final bool isAnonymousDisplay;
  final List<String> badges;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.createdAt,
    required this.currentStreak,
    required this.bestStreak,
    required this.streakFreezeUsed,
    required this.streakFreezeWeekKey,
    required this.lastLogDate,
    required this.isAnonymousDisplay,
    required this.badges,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final createdAt = map['createdAt'];
    return UserModel(
      uid: uid,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      photoUrl: (map['photoUrl'] as String?) ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (map['bestStreak'] as num?)?.toInt() ?? 0,
      streakFreezeUsed: (map['streakFreezeUsed'] as bool?) ?? false,
      streakFreezeWeekKey: (map['streakFreezeWeekKey'] as String?) ?? '',
      lastLogDate: (map['lastLogDate'] as String?) ?? '',
      isAnonymousDisplay: (map['isAnonymousDisplay'] as bool?) ?? false,
      badges: ((map['badges'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromMap(doc.data() ?? <String, dynamic>{}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'streakFreezeUsed': streakFreezeUsed,
      'streakFreezeWeekKey': streakFreezeWeekKey,
      'lastLogDate': lastLogDate,
      'isAnonymousDisplay': isAnonymousDisplay,
      'badges': badges,
    };
  }
}
