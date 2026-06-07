import '../../../../models/course_model.dart';
import '../../../../models/quiz_model.dart';
import '../../../../models/user_progress_model.dart';

List<CourseModel> filterPublishedCourses(
  List<CourseModel> courses, {
  required String query,
  String? selectedTag,
}) {
  final normalized = query.trim().toLowerCase();
  return courses.where((course) {
    if (selectedTag != null &&
        selectedTag.isNotEmpty &&
        !course.tags.contains(selectedTag)) {
      return false;
    }
    if (normalized.isEmpty) return true;
    if (course.title.toLowerCase().contains(normalized)) return true;
    if (course.description.toLowerCase().contains(normalized)) return true;
    return course.tags.any((tag) => tag.toLowerCase().contains(normalized));
  }).toList();
}

List<String> collectCourseTags(List<CourseModel> courses) {
  final tags = <String>{};
  for (final course in courses) {
    tags.addAll(course.tags);
  }
  final sorted = tags.toList()..sort();
  return sorted;
}

UserProgressModel? progressForCourse(
  List<UserProgressModel> allProgress,
  String courseId,
) {
  for (final progress in allProgress) {
    if (progress.courseId == courseId) return progress;
  }
  return null;
}

/// Student-facing quizzes must have at least one question.
List<QuizModel> filterPlayableQuizzes(List<QuizModel> quizzes) {
  return quizzes.where((quiz) => quiz.questionCount > 0).toList();
}

int syllabusGridCrossAxisCount(double width) => width >= 520 ? 3 : 2;

double syllabusGridAspectRatio(double width) => width >= 520 ? 0.78 : 0.72;
