import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import 'course_certificate_sheet.dart';

Future<void> handleLessonMarkComplete({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l10n,
  required String courseId,
  required String lessonId,
}) async {
  final user = ref.read(currentUserProvider).asData?.value;
  if (user == null) {
    context.push(AppRoutes.signIn);
    return;
  }

  final progress = ref.read(currentUserCourseProgressProvider(courseId)).value;
  if (progress == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.syllabusEnrollToComplete)),
    );
    return;
  }

  final wasCourseComplete =
      ref.read(currentUserCourseProgressProvider(courseId)).value?.isCourseCompleted ??
          false;

  final result = await ref
      .read(syllabusCourseActionsProvider(courseId).notifier)
      .markLessonComplete(lessonId);
  if (!context.mounted || !result.success) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.syllabusLessonCompleteSuccess)),
  );

  if (!wasCourseComplete && result.courseJustCompleted) {
    final course = ref.read(courseProvider(courseId)).value;
    if (course != null && context.mounted) {
      await CourseCertificateSheet.show(
        context,
        courseTitle: course.title,
        userName: user.name,
        completedAt: result.courseCompletedAt ?? DateTime.now(),
      );
    }
  }
}
