import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../models/notification_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../l10n/app_localizations.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final uid = ref.watch(authStateProvider).asData?.value?.uid;
    final notifications = ref.watch(notificationsProvider);
    final items = notifications.asData?.value ?? const <NotificationModel>[];
    final unread = items.where((n) => !n.isRead).length;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.more),
        ),
        title: Row(
          children: [
            Text(l10n.alerts, style: AppTextStyles.headlineMedium(context)),
            if (unread > 0) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: Text(
                  '$unread',
                  style: AppTextStyles.pill(context).copyWith(
                    color: AppColors.emeraldDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: uid == null || unread == 0
                ? null
                : () async {
                    await ref
                        .read(firestoreServiceProvider)
                        .markAllNotificationsRead(uid);
                  },
            child: Text(
              l10n.markAllRead,
              style: AppTextStyles.button(
                context,
              ).copyWith(color: AppColors.gold),
            ),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(
            l10n.failedLoadNotifications,
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(
                l10n.noNotificationsYet,
                style: AppTextStyles.bodyMedium(context),
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(0, 4.h, 0, 24.h),
            itemCount: rows.length,
            separatorBuilder: (_, _) => SizedBox(height: 8.h),
            itemBuilder: (_, i) => _NotificationRow(item: rows[i]),
          );
        },
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final NotificationModel item;
  const _NotificationRow({required this.item});

  String _resolvedMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (item.type == 'dua' && (item.senderName?.trim().isNotEmpty ?? false)) {
      return l10n.duaFromSender(item.senderName!.trim());
    }
    return item.message;
  }

  String _timeLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(item.createdAt);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return DateFormat('d MMM').format(item.createdAt);
  }

  IconData _iconForType() {
    switch (item.type) {
      case 'dua':
        return Icons.favorite_outline;
      case 'streak':
        return Icons.local_fire_department_outlined;
      case 'badge':
        return Icons.workspace_premium_outlined;
      case 'community':
      default:
        return Icons.notifications_outlined;
    }
  }

  String _routeForType() {
    switch (item.type) {
      case 'streak':
        return AppRoutes.home;
      case 'community':
        return AppRoutes.community;
      case 'badge':
        return AppRoutes.profile;
      case 'dua':
      default:
        return AppRoutes.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return CardContainer(
      onTap: () async {
        if (uid != null && !item.isRead) {
          await FirestoreService().markNotificationRead(uid, item.id);
        }
        if (!context.mounted) return;
        final route = _routeForType();
        if (route != AppRoutes.notifications) {
          context.go(route);
        }
      },
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      color: !item.isRead ? AppColors.goldCard : AppColors.cardDark,
      borderColor: !item.isRead ? AppColors.goldBorder : AppColors.cardBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              _iconForType(),
              color: !item.isRead ? AppColors.gold : AppColors.textSecondary,
              size: 18.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.type.toUpperCase(),
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  _resolvedMessage(context),
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(fontSize: 11.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  _timeLabel(context),
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(fontSize: 10.sp, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
