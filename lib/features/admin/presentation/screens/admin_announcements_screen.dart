import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/announcement_model.dart';
import '../../../../providers/announcement_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../widgets/admin_announcement_tile.dart';

class AdminAnnouncementsScreen extends ConsumerWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final uid = ref.watch(authStateProvider).asData?.value?.uid;

    if (!AdminConfig.isAdmin(uid)) {
      return AppScaffold(
        body: Center(
          child: Text(
            l10n.adminNotAuthorized,
            style: AppTextStyles.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final announcementsAsync = ref.watch(allAnnouncementsProvider);

    return AppScaffold(
      padding: EdgeInsets.zero,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.adminAnnouncementForm),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.emeraldDeep,
        child: Icon(Icons.add, size: 24.r),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
        children: [
          Text(
            l10n.adminAnnouncementsTitle,
            style: AppTextStyles.displayMedium(context),
          ),
          SizedBox(height: 16.h),
          announcementsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
            error: (_, _) => CardContainer(
              child: Text(
                l10n.adminLoadFailed,
                style: AppTextStyles.bodyMedium(context),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return CardContainer(
                  child: Text(
                    l10n.adminEmptyList,
                    style: AppTextStyles.bodyMedium(context),
                  ),
                );
              }
              return CardContainer(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      _AdminAnnouncementRow(announcement: items[i]),
                      if (i < items.length - 1) const Divider(),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}

class _AdminAnnouncementRow extends ConsumerWidget {
  const _AdminAnnouncementRow({required this.announcement});

  final AnnouncementModel announcement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return AdminAnnouncementTile(
      announcement: announcement,
      onTap: () => context.push(
        AppRoutes.adminAnnouncementForm,
        extra: announcement,
      ),
      onToggleActive: (value) async {
        try {
          await ref.read(firestoreServiceProvider).updateAnnouncement(
            announcement.id,
            <String, dynamic>{'isActive': value},
          );
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.adminToggleFailed)),
          );
        }
      },
      onDismissed: () async {
        try {
          await ref
              .read(firestoreServiceProvider)
              .deleteAnnouncement(announcement.id);
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.adminDeleteFailed)),
          );
        }
      },
    );
  }
}
