import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/services/syllabus_service.dart';
import '../core/utils/syllabus_badge_helper.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/user_progress_model.dart';
import 'auth_provider.dart';

final syllabusServiceProvider = Provider<SyllabusService>(
  (ref) => SyllabusService(),
);

final publishedCoursesProvider = StreamProvider<List<CourseModel>>((ref) {
  return ref.read(syllabusServiceProvider).publishedCoursesStream();
});

final allCoursesProvider = StreamProvider<List<CourseModel>>((ref) {
  return ref.read(syllabusServiceProvider).allCoursesStream();
});

final isListedCourseModeratorProvider = FutureProvider<bool>((ref) async {
  final uid = ref.watch(currentUserProvider).asData?.value?.uid;
  if (uid == null || uid.isEmpty) return false;
  return ref.read(syllabusServiceProvider).isListedCourseModerator(uid);
});

final courseProvider = StreamProvider.family<CourseModel?, String>(
  (ref, courseId) {
    return ref.read(syllabusServiceProvider).courseStream(courseId);
  },
);

final courseLessonsProvider = StreamProvider.family<List<LessonModel>, String>(
  (ref, courseId) {
    return ref.read(syllabusServiceProvider).lessonsStream(courseId);
  },
);

final publishedCourseLessonsProvider =
    StreamProvider.family<List<LessonModel>, String>((ref, courseId) {
  return ref.read(syllabusServiceProvider).publishedLessonsStream(courseId);
});

typedef LessonRef = ({String courseId, String lessonId});

final lessonProvider = StreamProvider.family<LessonModel?, LessonRef>(
  (ref, refKey) {
    return ref
        .read(syllabusServiceProvider)
        .lessonStream(refKey.courseId, refKey.lessonId);
  },
);

typedef UserCourseRef = ({String uid, String courseId});

final userCourseProgressProvider =
    StreamProvider.family<UserProgressModel?, UserCourseRef>((ref, refKey) {
  return ref
      .read(syllabusServiceProvider)
      .userProgressStream(refKey.uid, refKey.courseId);
});

final currentUserCourseProgressProvider =
    StreamProvider.family<UserProgressModel?, String>((ref, courseId) {
  final uid = ref.watch(currentUserProvider).asData?.value?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream<UserProgressModel?>.value(null);
  }
  return ref.read(syllabusServiceProvider).userProgressStream(uid, courseId);
});

final currentUserAllProgressProvider =
    StreamProvider<List<UserProgressModel>>((ref) {
  final uid = ref.watch(currentUserProvider).asData?.value?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream<List<UserProgressModel>>.value(const []);
  }
  return ref.read(syllabusServiceProvider).userAllProgressStream(uid);
});

class CourseProgressSummary {
  const CourseProgressSummary({
    required this.completedLessonCount,
    required this.totalLessons,
    required this.isEnrolled,
    required this.isCourseCompleted,
  });

  factory CourseProgressSummary.empty() {
    return const CourseProgressSummary(
      completedLessonCount: 0,
      totalLessons: 0,
      isEnrolled: false,
      isCourseCompleted: false,
    );
  }

  final int completedLessonCount;
  final int totalLessons;
  final bool isEnrolled;
  final bool isCourseCompleted;

  double get completionFraction {
    if (totalLessons <= 0) return 0;
    return (completedLessonCount / totalLessons).clamp(0.0, 1.0);
  }

  int get completionPercent => (completionFraction * 100).round();
}

/*
Purpose:
Derive enrollment and lesson completion stats for a course from live streams.

Response:
CourseProgressSummary with counts and enrollment flags.

Business Rules:
- totalLessons counts published lessons only.
- completedLessonCount comes from userProgress.completedLessons length.
- Unauthenticated users get empty summary.

Flow:
1. Watch published lessons and current-user progress for courseId.
2. Map AsyncValue data into summary fields.

Side Effects:
  None — read-only derivation.

Failure Cases:
- Missing stream data defaults to empty/zero counts.
*/
final courseProgressSummaryProvider =
    Provider.family<CourseProgressSummary, String>((ref, courseId) {
  final lessons =
      ref.watch(publishedCourseLessonsProvider(courseId)).value ?? const [];
  final progress = ref.watch(currentUserCourseProgressProvider(courseId)).value;

  if (progress == null) {
    return CourseProgressSummary(
      completedLessonCount: 0,
      totalLessons: lessons.length,
      isEnrolled: false,
      isCourseCompleted: false,
    );
  }

  return CourseProgressSummary(
    completedLessonCount: progress.completedLessons.length,
    totalLessons: lessons.length,
    isEnrolled: true,
    isCourseCompleted: progress.isCourseCompleted,
  );
});

class SyllabusCourseActionState {
  const SyllabusCourseActionState({this.isBusy = false, this.error});

  final bool isBusy;
  final String? error;

  SyllabusCourseActionState copyWith({bool? isBusy, String? error, bool clearError = false}) {
    return SyllabusCourseActionState(
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/*
Purpose:
Handle enrollment and lesson completion mutations for one course.

Response:
SyllabusCourseActionState tracking busy/error for UI feedback.

Business Rules:
- Requires authenticated user; returns false when signed out.
- markLessonComplete passes published lesson count for course completion.

Flow:
1. Resolve uid from currentUserProvider.
2. Call SyllabusService enroll or markLessonComplete.
3. Update busy/error flags around the async call.

Side Effects:
- Writes userProgress documents in Firestore.

Failure Cases:
- Missing auth, network, or permission errors surface via error + false return.
*/
class SyllabusCourseNotifier extends StateNotifier<SyllabusCourseActionState> {
  SyllabusCourseNotifier(this._ref, this._courseId)
      : super(const SyllabusCourseActionState());

  final Ref _ref;
  final String _courseId;

  String? get _uid => _ref.read(currentUserProvider).asData?.value?.uid;

  Future<bool> enroll() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty || _courseId.isEmpty) {
      state = state.copyWith(error: 'Sign in to enroll in this course.');
      return false;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _ref.read(syllabusServiceProvider).enrollUser(uid, _courseId);
      state = state.copyWith(isBusy: false);
      return true;
    } catch (_) {
      state = state.copyWith(isBusy: false, error: 'Unable to enroll right now.');
      return false;
    }
  }

  Future<bool> markLessonComplete(String lessonId) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty || _courseId.isEmpty || lessonId.isEmpty) {
      state = state.copyWith(error: 'Sign in to track lesson progress.');
      return false;
    }

    final totalLessons =
        _ref.read(publishedCourseLessonsProvider(_courseId)).value?.length;

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final service = _ref.read(syllabusServiceProvider);
      await service.markLessonComplete(
        uid: uid,
        courseId: _courseId,
        lessonId: lessonId,
        totalLessons: totalLessons,
      );
      final progress = await service.getUserProgress(uid, _courseId);
      if (progress?.isCourseCompleted == true) {
        await awardCourseGraduateBadgeIfNeeded(_ref, uid);
      }
      state = state.copyWith(isBusy: false);
      return true;
    } catch (_) {
      state = state.copyWith(
        isBusy: false,
        error: 'Unable to save lesson progress.',
      );
      return false;
    }
  }
}

final syllabusCourseActionsProvider = StateNotifierProvider.autoDispose
    .family<SyllabusCourseNotifier, SyllabusCourseActionState, String>(
  (ref, courseId) => SyllabusCourseNotifier(ref, courseId),
);
