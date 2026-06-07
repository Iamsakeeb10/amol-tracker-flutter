import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/course_model.dart';
import '../../models/lesson_model.dart';
import '../../models/user_progress_model.dart';

class SyllabusService {
  SyllabusService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection('courses');

  CollectionReference<Map<String, dynamic>> _lessons(String courseId) =>
      _courses.doc(courseId).collection('lessons');

  CollectionReference<Map<String, dynamic>> _userCourses(String uid) =>
      _firestore.collection('userProgress').doc(uid).collection('courses');

  /*
  Purpose:
  Create a new course document in Firestore.

  Response:
  The generated course document id.

  Business Rules:
  - Caller supplies a fully populated CourseModel (id may be empty).
  - publishedAt is only written when non-null on the model.

  Flow:
  1. add() course fields via CourseModel.toMap().
  2. Return generated document id.

  Side Effects:
  - Writes one Firestore document under courses/.

  Failure Cases:
  - Firestore permission/write errors bubble to caller.
  */
  Future<String> createCourse(CourseModel course) async {
    final doc = await _courses.add(course.toMap());
    return doc.id;
  }

  Future<void> updateCourse(String courseId, CourseModel course) async {
    if (courseId.isEmpty) return;
    await _courses.doc(courseId).update(course.toMap());
  }

  Future<void> updateCourseFields(
    String courseId,
    Map<String, dynamic> fields,
  ) async {
    if (courseId.isEmpty || fields.isEmpty) return;
    await _courses.doc(courseId).update(fields);
  }

  /*
  Purpose:
  Permanently remove a course and its lessons subcollection.

  Response:
  None.

  Business Rules:
  - Hard delete; quizzes subcollection is removed in the same batch.
  - Empty courseId is a no-op.

  Flow:
  1. Fetch all lesson and quiz docs for the course.
  2. Batch-delete subcollection docs then the course root doc.
  3. Commit batch.

  Side Effects:
  - Removes course, lessons, and quizzes from Firestore.

  Failure Cases:
  - Firestore delete errors bubble to caller.
  */
  Future<void> deleteCourse(String courseId) async {
    if (courseId.isEmpty) return;
    final courseRef = _courses.doc(courseId);
    final lessonDocs = await _lessons(courseId).get();
    final quizDocs = await courseRef.collection('quizzes').get();

    final batch = _firestore.batch();
    for (final doc in lessonDocs.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in quizDocs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(courseRef);
    await batch.commit();
  }

  Future<CourseModel?> getCourse(String courseId) async {
    if (courseId.isEmpty) return null;
    final snap = await _courses.doc(courseId).get();
    if (!snap.exists) return null;
    return CourseModel.fromDoc(snap);
  }

  Stream<CourseModel?> courseStream(String courseId) {
    if (courseId.isEmpty) {
      return Stream<CourseModel?>.value(null);
    }
    return _courses.doc(courseId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CourseModel.fromDoc(doc);
    });
  }

  /*
  Purpose:
  Stream all courses for admin management, ordered by display order.

  Response:
  Emits full course list sorted by order ascending.

  Business Rules:
  - Includes draft and published courses.
  - Falls back to client-side sort when composite index is missing.

  Flow:
  1. Subscribe to courses ordered by order.
  2. Map docs to CourseModel.
  3. On index error, subscribe to full collection and sort client-side.

  Side Effects:
  - Opens a live Firestore listener.

  Failure Cases:
  - Non-index stream errors propagate to caller.
  */
  Stream<List<CourseModel>> allCoursesStream() {
    return _orderedCoursesStream(includeDrafts: true);
  }

  Stream<List<CourseModel>> publishedCoursesStream() {
    return _orderedCoursesStream(includeDrafts: false);
  }

  Stream<List<CourseModel>> _orderedCoursesStream({
    required bool includeDrafts,
  }) {
    Query<Map<String, dynamic>> query() {
      if (includeDrafts) {
        return _courses.orderBy('order');
      }
      return _courses
          .where('status', isEqualTo: CourseStatus.published.name)
          .orderBy('order');
    }

    List<CourseModel> mapDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    ) {
      return docs.map(CourseModel.fromDoc).toList();
    }

    List<CourseModel> fallbackMapDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    ) {
      final items = docs.map(CourseModel.fromDoc).toList();
      if (!includeDrafts) {
        items.retainWhere((course) => course.isPublished);
      }
      items.sort((a, b) => a.order.compareTo(b.order));
      return items;
    }

    return _resilientQueryStream(
      query: query,
      mapDocs: mapDocs,
      fallbackQuery: () => _courses,
      fallbackMapDocs: fallbackMapDocs,
    );
  }

  /*
  Purpose:
  Publish a course so students can discover and enroll.

  Response:
  None.

  Business Rules:
  - Sets status to published.
  - publishedAt uses server timestamp on every publish action.

  Flow:
  1. update() status and publishedAt on courses/{courseId}.

  Side Effects:
  - Writes to Firestore.

  Failure Cases:
  - Firestore write errors bubble to caller.
  */
  Future<void> publishCourse(String courseId) async {
    if (courseId.isEmpty) return;
    await _courses.doc(courseId).update(<String, dynamic>{
      'status': CourseStatus.published.name,
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unpublishCourse(String courseId) async {
    if (courseId.isEmpty) return;
    await _courses.doc(courseId).update(<String, dynamic>{
      'status': CourseStatus.draft.name,
      'publishedAt': FieldValue.delete(),
    });
  }

  Future<String> createLesson(LessonModel lesson) async {
    if (lesson.courseId.isEmpty) {
      throw ArgumentError('lesson.courseId must not be empty');
    }
    final doc = await _lessons(lesson.courseId).add(lesson.toMap());
    return doc.id;
  }

  Future<void> updateLesson(LessonModel lesson) async {
    if (lesson.courseId.isEmpty || lesson.id.isEmpty) return;
    await _lessons(lesson.courseId).doc(lesson.id).update(lesson.toMap());
  }

  Future<void> deleteLesson(String courseId, String lessonId) async {
    if (courseId.isEmpty || lessonId.isEmpty) return;
    await _lessons(courseId).doc(lessonId).delete();
  }

  Future<LessonModel?> getLesson(String courseId, String lessonId) async {
    if (courseId.isEmpty || lessonId.isEmpty) return null;
    final snap = await _lessons(courseId).doc(lessonId).get();
    if (!snap.exists) return null;
    return LessonModel.fromDoc(snap, courseId: courseId);
  }

  Stream<LessonModel?> lessonStream(String courseId, String lessonId) {
    if (courseId.isEmpty || lessonId.isEmpty) {
      return Stream<LessonModel?>.value(null);
    }
    return _lessons(courseId).doc(lessonId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return LessonModel.fromDoc(doc, courseId: courseId);
    });
  }

  Stream<List<LessonModel>> lessonsStream(String courseId) {
    return _lessonsOrderedStream(
      courseId: courseId,
      publishedOnly: false,
    );
  }

  Stream<List<LessonModel>> publishedLessonsStream(String courseId) {
    return _lessonsOrderedStream(
      courseId: courseId,
      publishedOnly: true,
    );
  }

  Stream<List<LessonModel>> _lessonsOrderedStream({
    required String courseId,
    required bool publishedOnly,
  }) {
    if (courseId.isEmpty) {
      return Stream<List<LessonModel>>.value(const []);
    }

    Query<Map<String, dynamic>> query() {
      if (publishedOnly) {
        return _lessons(courseId)
            .where('isPublished', isEqualTo: true)
            .orderBy('order');
      }
      return _lessons(courseId).orderBy('order');
    }

    List<LessonModel> mapDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    ) {
      return docs
          .map((doc) => LessonModel.fromDoc(doc, courseId: courseId))
          .toList();
    }

    List<LessonModel> fallbackMapDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    ) {
      final items = docs
          .map((doc) => LessonModel.fromDoc(doc, courseId: courseId))
          .toList();
      if (publishedOnly) {
        items.retainWhere((lesson) => lesson.isPublished);
      }
      items.sort((a, b) => a.order.compareTo(b.order));
      return items;
    }

    return _resilientQueryStream(
      query: query,
      mapDocs: mapDocs,
      fallbackQuery: () => _lessons(courseId),
      fallbackMapDocs: fallbackMapDocs,
    );
  }

  Future<void> reorderLessons(
    String courseId,
    List<String> orderedLessonIds,
  ) async {
    if (courseId.isEmpty || orderedLessonIds.isEmpty) return;
    final batch = _firestore.batch();
    for (var i = 0; i < orderedLessonIds.length; i++) {
      final lessonId = orderedLessonIds[i];
      if (lessonId.isEmpty) continue;
      batch.update(_lessons(courseId).doc(lessonId), <String, dynamic>{
        'order': i,
      });
    }
    await batch.commit();
  }

  /*
  Purpose:
  Enroll a user in a course by creating their progress document.

  Response:
  None.

  Business Rules:
  - No-op when already enrolled.
  - enrolledAt uses server timestamp on first enrollment.

  Flow:
  1. Check userProgress/{uid}/courses/{courseId} exists.
  2. set() with enrolledAt when missing.

  Side Effects:
  - Writes one Firestore document under userProgress/.

  Failure Cases:
  - Firestore write errors bubble to caller.
  */
  Future<void> enrollUser(String uid, String courseId) async {
    if (uid.isEmpty || courseId.isEmpty) return;
    final ref = _userCourses(uid).doc(courseId);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set(<String, dynamic>{
      'enrolledAt': FieldValue.serverTimestamp(),
      'completedLessons': <String>[],
    });
  }

  Future<bool> isUserEnrolled(String uid, String courseId) async {
    if (uid.isEmpty || courseId.isEmpty) return false;
    final snap = await _userCourses(uid).doc(courseId).get();
    return snap.exists;
  }

  Future<UserProgressModel?> getUserProgress(
    String uid,
    String courseId,
  ) async {
    if (uid.isEmpty || courseId.isEmpty) return null;
    final snap = await _userCourses(uid).doc(courseId).get();
    if (!snap.exists) return null;
    return UserProgressModel.fromDoc(snap);
  }

  Stream<UserProgressModel?> userProgressStream(
    String uid,
    String courseId,
  ) {
    if (uid.isEmpty || courseId.isEmpty) {
      return Stream<UserProgressModel?>.value(null);
    }
    return _userCourses(uid).doc(courseId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProgressModel.fromDoc(doc);
    });
  }

  Stream<List<UserProgressModel>> userAllProgressStream(String uid) {
    if (uid.isEmpty) {
      return Stream<List<UserProgressModel>>.value(const []);
    }
    return _userCourses(uid).snapshots().map(
          (snap) => snap.docs.map(UserProgressModel.fromDoc).toList(),
        );
  }

  /*
  Purpose:
  Record a lesson as completed and optionally mark the whole course done.

  Response:
  None.

  Business Rules:
  - User must be enrolled; auto-enrolls if progress doc is missing.
  - completedLessons uses arrayUnion (idempotent per lesson).
  - When completed lesson count reaches totalLessons, sets completedAt.

  Flow:
  1. Ensure enrollment exists.
  2. arrayUnion lessonId into completedLessons.
  3. If all lessons done, set completedAt server timestamp.

  Side Effects:
  - Writes to userProgress/{uid}/courses/{courseId}.

  Failure Cases:
  - Firestore write errors bubble to caller.
  */
  Future<void> markLessonComplete({
    required String uid,
    required String courseId,
    required String lessonId,
    int? totalLessons,
  }) async {
    if (uid.isEmpty || courseId.isEmpty || lessonId.isEmpty) return;

    final ref = _userCourses(uid).doc(courseId);
    final snap = await ref.get();
    if (!snap.exists) {
      await enrollUser(uid, courseId);
    }

    await ref.update(<String, dynamic>{
      'completedLessons': FieldValue.arrayUnion(<String>[lessonId]),
    });

    if (totalLessons == null || totalLessons <= 0) return;

    final updated = await ref.get();
    final progress = UserProgressModel.fromDoc(updated);
    if (progress.completedLessons.length >= totalLessons &&
        !progress.isCourseCompleted) {
      await ref.update(<String, dynamic>{
        'completedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<T>> _resilientQueryStream<T>({
    required Query<Map<String, dynamic>> Function() query,
    required List<T> Function(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    )
    mapDocs,
    required Query<Map<String, dynamic>> Function() fallbackQuery,
    required List<T> Function(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    )
    fallbackMapDocs,
  }) {
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> subscription;
    final controller = StreamController<List<T>>();
    var usingFallback = false;

    void listenFallback() {
      usingFallback = true;
      subscription = fallbackQuery().snapshots().listen(
        (snap) => controller.add(fallbackMapDocs(snap.docs)),
        onError: controller.addError,
      );
    }

    void listenPrimary() {
      subscription = query().snapshots().listen(
        (snap) => controller.add(mapDocs(snap.docs)),
        onError: (Object error, StackTrace stackTrace) {
          final isIndexError =
              error is FirebaseException && error.code == 'failed-precondition';
          if (!usingFallback && isIndexError) {
            subscription.cancel();
            listenFallback();
            return;
          }
          controller.addError(error, stackTrace);
        },
      );
    }

    listenPrimary();
    controller.onCancel = () => subscription.cancel();
    return controller.stream;
  }

  Future<bool> isListedCourseModerator(String uid) async {
    if (uid.isEmpty) return false;
    final snap = await _courses
        .where('moderators', arrayContains: uid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}
