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
import '../../../../models/app_config_model.dart';
import '../../../../providers/app_config_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../widgets/admin_app_config_tile.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminAppConfigListScreen extends ConsumerWidget {
  const AdminAppConfigListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;

    if (!AdminConfig.isFullAdmin(user?.email, role: user?.role)) {
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

    final configsAsync = ref.watch(appConfigsProvider);

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AdminAppBar(title: l10n.adminAppConfigTitle),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminAppConfigForm),
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
            title: l10n.adminAppConfigTitle,
          ),
          SizedBox(height: 18.h),
          configsAsync.when(
            loading: () => const _AdminListShimmer(),
            error: (_, _) => CardContainer(
              child: Text(
                l10n.adminLoadFailed,
                style: AppTextStyles.bodyMedium(context),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return CardContainer(
                  padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
                  child: Column(
                    children: [
                      Icon(
                        Icons.system_update_outlined,
                        color: AppColors.gold,
                        size: 36.r,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        l10n.adminEmptyList,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium(context),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: items
                    .map((c) => _AdminConfigRow(config: c))
                    .toList(),
              );
            },
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
          (_) => Padding(
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

class _AdminConfigRow extends ConsumerWidget {
  const _AdminConfigRow({required this.config});

  final AppConfigModel config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return AdminAppConfigTile(
      config: config,
      onTap: () => context.push(
        AppRoutes.adminAppConfigForm,
        extra: config,
      ),
      onToggleActive: (value) async {
        try {
          await ref.read(firestoreServiceProvider).updateAppConfig(
            config.id,
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
              .deleteAppConfig(config.id);
        } catch (_) {
          if (!context.mounted) return;
          showAdminSnackBar(context, message: l10n.adminDeleteFailed, isError: true);
        }
      },
    );
  }
}
