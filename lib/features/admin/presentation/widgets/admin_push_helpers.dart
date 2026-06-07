import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'admin_announcement_helpers.dart';

/// Push types accepted by [AdminPushGatewayService] / admin-push worker.
const kAdminPushTypes = <String>[
  'announcement',
  'reminder',
  'dua',
  'hadith',
  'syllabus_course',
];

String adminPushTypeLabel(AppLocalizations l10n, String type) {
  switch (type) {
    case 'syllabus_course':
      return l10n.adminPushTypeSyllabusCourse;
    default:
      return typeLabel(l10n, type);
  }
}

IconData iconForAdminPushType(String type) {
  switch (type) {
    case 'syllabus_course':
      return Icons.school_outlined;
    default:
      return iconForAnnouncementType(type);
  }
}

String normalizeAdminPushType(String? type) {
  if (type != null && kAdminPushTypes.contains(type)) return type;
  return 'announcement';
}
