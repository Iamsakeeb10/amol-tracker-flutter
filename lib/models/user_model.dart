import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

enum UserAmalProfile {
  unset,
  male,
  female;

  static UserAmalProfile fromString(String? value) {
    switch (value) {
      case 'male':
        return UserAmalProfile.male;
      case 'female':
        return UserAmalProfile.female;
      default:
        return UserAmalProfile.unset;
    }
  }
}

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
  final String streakFreezeDate;
  final bool isAnonymousDisplay;
  final bool showOnLeaderboard;
  final List<String> badges;
  final List<String> seenBadgeCelebrations;
  final List<String> seenAnnouncements;
  final UserRole role;
  final int lmsXp;
  final bool hasDismissedLoggingReminder;
  final String? gender;
  final bool specialTimeActive;
  final bool genderPromptDismissed;

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
    this.streakFreezeDate = '',
    required this.isAnonymousDisplay,
    required this.showOnLeaderboard,
    required this.badges,
    required this.seenBadgeCelebrations,
    required this.seenAnnouncements,
    this.role = UserRole.user,
    this.lmsXp = 0,
    this.hasDismissedLoggingReminder = false,
    this.gender,
    this.specialTimeActive = false,
    this.genderPromptDismissed = false,
  });

  UserAmalProfile get amalProfile => UserAmalProfile.fromString(gender);

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
      streakFreezeDate: (map['streakFreezeDate'] as String?) ?? '',
      isAnonymousDisplay: (map['isAnonymousDisplay'] as bool?) ?? false,
      showOnLeaderboard: (map['showOnLeaderboard'] as bool?) ?? true,
      badges: ((map['badges'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      seenBadgeCelebrations:
          ((map['seenBadgeCelebrations'] as List<dynamic>?) ?? const [])
              .map((item) => item.toString())
              .toList(),
      seenAnnouncements:
          ((map['seenAnnouncements'] as List<dynamic>?) ?? const [])
              .map((item) => item.toString())
              .toList(),
      role: UserRole.fromString(map['role'] as String?),
      lmsXp: (map['lmsXp'] as num?)?.toInt() ?? 0,
      hasDismissedLoggingReminder: (map['hasDismissedLoggingReminder'] as bool?) ?? false,
      gender: map['gender'] as String?,
      specialTimeActive: (map['specialTimeActive'] as bool?) ?? false,
      genderPromptDismissed: (map['genderPromptDismissed'] as bool?) ?? false,
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
      if (streakFreezeDate.isNotEmpty) 'streakFreezeDate': streakFreezeDate,
      'isAnonymousDisplay': isAnonymousDisplay,
      'showOnLeaderboard': showOnLeaderboard,
      'badges': badges,
      'seenBadgeCelebrations': seenBadgeCelebrations,
      'seenAnnouncements': seenAnnouncements,
      if (role != UserRole.user) 'role': role.firestoreValue,
      if (lmsXp > 0) 'lmsXp': lmsXp,
      'hasDismissedLoggingReminder': hasDismissedLoggingReminder,
      if (gender != null) 'gender': gender,
      if (specialTimeActive) 'specialTimeActive': true,
      if (genderPromptDismissed) 'genderPromptDismissed': true,
    };
  }
}
