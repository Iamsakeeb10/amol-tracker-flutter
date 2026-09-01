import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../../../../models/user_model.dart';
import '../../../../models/user_role.dart';

final adminUserSearchProvider = StateNotifierProvider.autoDispose<AdminUserSearchNotifier, AsyncValue<UserModel?>>((ref) {
  return AdminUserSearchNotifier();
});

class AdminUserSearchNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AdminUserSearchNotifier() : super(const AsyncValue.data(null));

  Future<void> searchUserByEmail(String email) async {
    if (email.trim().isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        state = const AsyncValue.data(null);
      } else {
        final doc = querySnapshot.docs.first;
        final user = UserModel.fromDoc(doc);
        state = AsyncValue.data(user);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateUserRole(String uid, UserRole newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': newRole.firestoreValue,
      });
      
      final currentUser = state.value;
      if (currentUser != null && currentUser.uid == uid) {
        state = AsyncValue.data(UserModel(
          uid: currentUser.uid,
          name: currentUser.name,
          email: currentUser.email,
          photoUrl: currentUser.photoUrl,
          createdAt: currentUser.createdAt,
          currentStreak: currentUser.currentStreak,
          bestStreak: currentUser.bestStreak,
          streakFreezeUsed: currentUser.streakFreezeUsed,
          streakFreezeWeekKey: currentUser.streakFreezeWeekKey,
          lastLogDate: currentUser.lastLogDate,
          streakFreezeDate: currentUser.streakFreezeDate,
          isAnonymousDisplay: currentUser.isAnonymousDisplay,
          showOnLeaderboard: currentUser.showOnLeaderboard,
          badges: currentUser.badges,
          seenBadgeCelebrations: currentUser.seenBadgeCelebrations,
          seenAnnouncements: currentUser.seenAnnouncements,
          role: newRole,
          lmsXp: currentUser.lmsXp,
          hasDismissedLoggingReminder: currentUser.hasDismissedLoggingReminder,
          dismissedLoggingReminderVersion: currentUser.dismissedLoggingReminderVersion,
          gender: currentUser.gender,
          specialTimeActive: currentUser.specialTimeActive,
          genderPromptDismissed: currentUser.genderPromptDismissed,
        ));
      }
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }
}
