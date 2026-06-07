import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/announcement_model.dart';
import 'auth_provider.dart';

final announcementsProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  return ref.read(firestoreServiceProvider).announcementsStream();
});

final allAnnouncementsProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  return ref.read(firestoreServiceProvider).allAnnouncementsStream();
});

/*
Purpose:
Resolve the single announcement that should be shown next on HomeScreen.

Response:
AnnouncementModel? — first eligible active announcement, or null.

Business Rules:
- Requires an authenticated user with a loaded profile.
- showOnce: true → skip if id is in user.seenAnnouncements.
- showOnce: false → always eligible while active.
- Newest active announcement wins when multiple are eligible.

Flow:
1. Read announcements stream value (default []).
2. Read current user profile.
3. Return first announcement passing seen/showOnce rules.

Side Effects:
  None — read-only derivation.

Failure Cases:
- Null user or empty announcements → null.
*/
final pendingAnnouncementProvider = Provider<AnnouncementModel?>((ref) {
  final announcements = ref.watch(announcementsProvider).value ?? const [];
  final user = ref.watch(currentUserProvider).value;
  if (user == null || announcements.isEmpty) return null;

  final seen = user.seenAnnouncements;
  for (final announcement in announcements) {
    if (!announcement.showOnce || !seen.contains(announcement.id)) {
      return announcement;
    }
  }
  return null;
});
