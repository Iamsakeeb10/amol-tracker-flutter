import '../../models/course_model.dart';
import '../../models/user_role.dart';

class AdminConfig {
  AdminConfig._();

  static const Set<String> _adminUids = {'WLZuhj6DaIT2x05uY6fiS88X6852'};

  static bool isUidAdmin(String? uid) =>
      uid != null && _adminUids.contains(uid);

  /// Full admin access (announcements, push, all courses).
  static bool isFullAdmin(String? uid, {UserRole? role}) =>
      isUidAdmin(uid) || role == UserRole.admin;

  /// Backward-compatible alias for full admin checks.
  static bool isAdmin(String? uid, {UserRole? role}) =>
      isFullAdmin(uid, role: role);

  /// Can open syllabus course management screens.
  static bool canAccessCourseAdmin(String? uid, {UserRole? role}) =>
      isFullAdmin(uid, role: role) || role == UserRole.moderator;

  /// Can manage a specific course (full admin, global moderator, or listed moderator).
  static bool canModerateCourse(
    String? uid,
    CourseModel course, {
    UserRole? role,
  }) =>
      isFullAdmin(uid, role: role) ||
      role == UserRole.moderator ||
      (uid != null && course.moderators.contains(uid));

  static bool isFullAdminRoute(String location) {
    return location == '/admin/announcements' ||
        location == '/admin/announcement-form' ||
        location == '/admin/push-notification' ||
        location == '/admin/amal-fields' ||
        location == '/admin/amal-field-form';
  }

  static bool isCourseAdminRoute(String location) {
    return location.startsWith('/admin/courses') ||
        location == '/admin/course-form' ||
        location == '/admin/lesson-form' ||
        location == '/admin/quiz-form' ||
        location == '/admin/question-editor';
  }
}
