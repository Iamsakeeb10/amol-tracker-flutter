import '../../models/course_model.dart';
import '../../models/user_role.dart';

class AdminConfig {
  AdminConfig._();

  static const Set<String> _adminEmails = {'shakibshovon.10@gmail.com'};

  /// The primary admin email used for targeted push notifications.
  static String? get adminEmail => _adminEmails.isNotEmpty ? _adminEmails.first : null;

  static bool isEmailAdmin(String? email) =>
      email != null && _adminEmails.contains(email);

  /// Full admin access (announcements, push, all courses).
  static bool isFullAdmin(String? email, {UserRole? role}) =>
      isEmailAdmin(email) || role == UserRole.admin;

  /// Backward-compatible alias for full admin checks.
  static bool isAdmin(String? email, {UserRole? role}) =>
      isFullAdmin(email, role: role);

  /// Can open syllabus course management screens.
  static bool canAccessCourseAdmin(String? email, {UserRole? role}) =>
      isFullAdmin(email, role: role) || role == UserRole.moderator;

  /// Can manage a specific course (full admin, global moderator, or listed moderator).
  static bool canModerateCourse(
    String? email,
    CourseModel course, {
    UserRole? role,
  }) =>
      isFullAdmin(email, role: role) ||
      role == UserRole.moderator ||
      (email != null && course.moderators.contains(email));

  static bool isFullAdminRoute(String location) {
    return location == '/admin/announcements' ||
        location == '/admin/announcement-form' ||
        location == '/admin/push-notification' ||
        location == '/admin/amal-fields' ||
        location == '/admin/amal-field-form' ||
        location == '/admin/app-configs' ||
        location == '/admin/app-config-form';
  }

  static bool isCourseAdminRoute(String location) {
    return location.startsWith('/admin/courses') ||
        location == '/admin/course-form' ||
        location == '/admin/lesson-form' ||
        location == '/admin/quiz-form' ||
        location == '/admin/question-editor';
  }
}
