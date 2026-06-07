import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

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
import '../widgets/admin_shared_widgets.dart';

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
      appBar: AdminAppBar(title: l10n.adminAnnouncementsTitle),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminAnnouncementForm),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.emeraldDeep,
        icon: Icon(Icons.add, size: 20.r),
        label: Text(
          l10n.adminFormCreateTitle,
          style: AppTextStyles.button(context).copyWith(
            color: AppColors.emeraldDeep,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
        children: [
          AdminScreenHeader(
            subtitle: l10n.adminSectionTitle.toUpperCase(),
            title: l10n.adminAnnouncementsTitle,
          ),
          SizedBox(height: 18.h),
          announcementsAsync.when(
            loading: () => const _AdminListShimmer(),
            error: (_, _) => CardContainer(
              child: Text(
                l10n.adminLoadFailed,
                style: AppTextStyles.bodyMedium(context),
              ),
            ),
            data: (items) {
              if (items.isEmpty) return _AdminEmptyList(message: l10n.adminEmptyList);
              return Column(
                children: items
                    .map((a) => _AdminAnnouncementRow(announcement: a))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminEmptyList extends StatelessWidget {
  const _AdminEmptyList({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
      child: Column(
        children: [
          Icon(
            Icons.campaign_outlined,
            color: AppColors.gold,
            size: 36.r,
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }
}

class _AdminListShimmer extends StatelessWidget {
  const _AdminListShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Container(
              height: 72.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
        ),
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
          showAdminSnackBar(context, message: l10n.adminToggleFailed, isError: true);
        }
      },
      onDismissed: () async {
        try {
          await ref
              .read(firestoreServiceProvider)
              .deleteAnnouncement(announcement.id);
        } catch (_) {
          if (!context.mounted) return;
          showAdminSnackBar(context, message: l10n.adminDeleteFailed, isError: true);
        }
      },
    );
  }
}
