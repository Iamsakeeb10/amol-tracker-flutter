import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';

const kCourseGraduateBadgeId = 'courseGraduate';

/*
Purpose:
Award the course-graduate badge when a user completes their first syllabus course.

Response:
None.

Business Rules:
- Badge id is courseGraduate; idempotent if already unlocked.
- Requires a signed-in user with a readable currentUserProvider value.

Flow:
1. Read current user badges from currentUserProvider.
2. Skip when courseGraduate is already present.
3. arrayUnion the badge id on users/{uid}.badges.

Side Effects:
- Writes to Firestore user document; triggers badge celebration stream.

Failure Cases:
- Missing user or Firestore errors are swallowed (non-blocking).
*/
Future<void> awardCourseGraduateBadgeIfNeeded(Ref ref, String uid) async {
  if (uid.isEmpty) return;

  final user = ref.read(currentUserProvider).asData?.value;
  if (user == null || user.badges.contains(kCourseGraduateBadgeId)) return;

  final fs = ref.read(firestoreServiceProvider);
  try {
    await fs.updateUser(uid, <String, dynamic>{
      'badges': <String>[...user.badges, kCourseGraduateBadgeId],
    });
  } catch (_) {
    // Progress is saved; badge can be reconciled on next completion attempt.
  }
}
