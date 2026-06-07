import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lesson_bookmark_model.dart';
import 'auth_provider.dart';
import 'syllabus_provider.dart';

final lessonBookmarksProvider = StreamProvider<List<LessonBookmarkModel>>((ref) {
  final uid = ref.watch(currentUserProvider).asData?.value?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream.value(const []);
  }
  return ref.read(lmsReviewServiceProvider).bookmarksStream(uid);
});

typedef BookmarkRef = ({String courseId, String lessonId});

final isLessonBookmarkedProvider =
    StreamProvider.family<bool, BookmarkRef>((ref, refKey) {
  final uid = ref.watch(currentUserProvider).asData?.value?.uid;
  if (uid == null || uid.isEmpty) return Stream.value(false);
  return ref.read(lmsReviewServiceProvider).isBookmarkedStream(
        uid: uid,
        courseId: refKey.courseId,
        lessonId: refKey.lessonId,
      );
});

Future<void> toggleLessonBookmark(
  Ref ref, {
  required String courseId,
  required String lessonId,
  String? lessonTitle,
  String? courseTitle,
}) async {
  final uid = ref.read(currentUserProvider).asData?.value?.uid;
  if (uid == null || uid.isEmpty) return;
  await ref.read(lmsReviewServiceProvider).toggleBookmark(
        uid: uid,
        courseId: courseId,
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        courseTitle: courseTitle,
      );
}
