import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/announcement_model.dart';

enum AdminAnnouncementStatus { live, scheduled, expired, off }

const kAnnouncementTypes = <String>[
  'reminder',
  'announcement',
  'dua',
  'hadith',
];

String normalizeAnnouncementType(String? type) {
  if (type != null && kAnnouncementTypes.contains(type)) return type;
  return 'announcement';
}

bool isAnnouncementScheduleValid({
  DateTime? startsAt,
  DateTime? expiresAt,
}) {
  if (startsAt == null || expiresAt == null) return true;
  return expiresAt.isAfter(startsAt);
}

AdminAnnouncementStatus statusForAnnouncement(AnnouncementModel item) {
  if (!item.isActive) return AdminAnnouncementStatus.off;
  final now = DateTime.now();
  if (item.startsAt != null && now.isBefore(item.startsAt!)) {
    return AdminAnnouncementStatus.scheduled;
  }
  if (item.expiresAt != null && now.isAfter(item.expiresAt!)) {
    return AdminAnnouncementStatus.expired;
  }
  if (item.isCurrentlyActive) return AdminAnnouncementStatus.live;
  return AdminAnnouncementStatus.off;
}

String statusLabel(AppLocalizations l10n, AdminAnnouncementStatus status) {
  switch (status) {
    case AdminAnnouncementStatus.live:
      return l10n.adminStatusLive;
    case AdminAnnouncementStatus.scheduled:
      return l10n.adminStatusScheduled;
    case AdminAnnouncementStatus.expired:
      return l10n.adminStatusExpired;
    case AdminAnnouncementStatus.off:
      return l10n.adminStatusOff;
  }
}

Color statusColor(AdminAnnouncementStatus status) {
  switch (status) {
    case AdminAnnouncementStatus.live:
      return AppColors.success;
    case AdminAnnouncementStatus.scheduled:
      return AppColors.gold;
    case AdminAnnouncementStatus.expired:
      return AppColors.warning;
    case AdminAnnouncementStatus.off:
      return AppColors.textMuted;
  }
}

String typeLabel(AppLocalizations l10n, String type) {
  switch (type) {
    case 'reminder':
      return l10n.announcementTypeReminder;
    case 'dua':
      return l10n.announcementTypeDua;
    case 'hadith':
      return l10n.announcementTypeHadith;
    case 'announcement':
    default:
      return l10n.announcementTypeAnnouncement;
  }
}

IconData iconForAnnouncementType(String type) {
  switch (type) {
    case 'dua':
      return Icons.volunteer_activism;
    case 'reminder':
      return Icons.notifications_outlined;
    case 'hadith':
      return Icons.menu_book_outlined;
    case 'announcement':
    default:
      return Icons.campaign_outlined;
  }
}

Map<String, dynamic> announcementToFirestoreMap({
  required String title,
  required String message,
  required String type,
  required bool isActive,
  required bool showOnce,
  String? arabicText,
  String? imageUrl,
  DateTime? startsAt,
  DateTime? expiresAt,
  bool forUpdate = false,
}) {
  final map = <String, dynamic>{
    'title': title.trim(),
    'message': message.trim(),
    'type': type,
    'isActive': isActive,
    'showOnce': showOnce,
  };
  _putOptionalField(
    map,
    'arabicText',
    _nullableTrim(arabicText),
    forUpdate: forUpdate,
  );
  _putOptionalField(
    map,
    'imageUrl',
    _nullableTrim(imageUrl),
    forUpdate: forUpdate,
  );
  _putOptionalField(
    map,
    'startsAt',
    startsAt != null ? Timestamp.fromDate(startsAt) : null,
    forUpdate: forUpdate,
  );
  _putOptionalField(
    map,
    'expiresAt',
    expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
    forUpdate: forUpdate,
  );
  return map;
}

void _putOptionalField(
  Map<String, dynamic> map,
  String key,
  Object? value, {
  required bool forUpdate,
}) {
  if (value != null) {
    map[key] = value;
    return;
  }
  if (forUpdate) map[key] = FieldValue.delete();
}

String? _nullableTrim(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
