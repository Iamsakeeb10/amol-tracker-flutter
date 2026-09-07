import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/personal_amol_provider.dart';
import '../../../../providers/personal_amol_report_provider.dart';
import '../../../../providers/report_provider.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../reports/presentation/widgets/report_personal_amol_breakdown.dart';

/// Own-profile section showing personal amol history for the current Hijri
/// month (same window as prayer habits), with Manage linking to the list.
class ProfilePersonalAmolSection extends ConsumerWidget {
  const ProfilePersonalAmolSection({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ym = IslamicDateService.currentHijriYearMonth();
    final range = monthlyRange(ym.year, ym.month);
    final reportKey = PersonalAmolReportKey(
      uid: uid,
      startHijri: range.start,
      endHijri: range.end,
    );
    final amolsAsync = ref.watch(activePersonalAmolProvider(uid));
    final statsAsync = ref.watch(personalAmolReportProvider(reportKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.personalAmolSectionTitle,
                style: AppTextStyles.headlineMedium(context),
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.personalAmolList),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                minimumSize: Size(44.r, 44.r),
              ),
              child: Text(
                l10n.personalAmolManage,
                style: AppTextStyles.label(context).copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        amolsAsync.when(
          loading: () => const _ProfilePersonalAmolSkeleton(),
          error: (_, _) => _ProfilePersonalAmolError(
            onRetry: () {
              ref.invalidate(activePersonalAmolProvider(uid));
              ref.invalidate(personalAmolReportProvider(reportKey));
            },
          ),
          data: (amols) {
            if (amols.isEmpty) {
              return _ProfileEmptyPersonalAmol(
                onManage: () => context.push(AppRoutes.personalAmolList),
              );
            }

            return statsAsync.when(
              loading: () => const _ProfilePersonalAmolSkeleton(),
              error: (_, _) => _ProfilePersonalAmolError(
                onRetry: () =>
                    ref.invalidate(personalAmolReportProvider(reportKey)),
              ),
              data: (stats) {
                if (stats.isEmpty) {
                  return CardContainer(
                    child: Text(
                      l10n.personalAmolEmptySubtitle,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return ReportPersonalAmolBreakdown(
                  stats: stats,
                  compact: true,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ProfilePersonalAmolSkeleton extends StatelessWidget {
  const _ProfilePersonalAmolSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
      child: CardContainer(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.cardBorder,
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Row(
                  children: [
                    Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100.w,
                            height: 10.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            width: 60.w,
                            height: 8.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 64.w,
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfilePersonalAmolError extends StatelessWidget {
  const _ProfilePersonalAmolError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.personalAmolLoadFailed,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 10.h),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold,
                minimumSize: Size(44.r, 44.r),
                padding: EdgeInsets.symmetric(horizontal: 8.w),
              ),
              child: Text(
                l10n.reportsRetry,
                style: AppTextStyles.label(context).copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileEmptyPersonalAmol extends StatelessWidget {
  const _ProfileEmptyPersonalAmol({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CardContainer(
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.goldCard,
              borderRadius: BorderRadius.circular(AppRadius.md.r - 2),
              border: Border.all(color: AppColors.goldBorder),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.gold,
              size: 18.r,
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.personalAmolEmptyProfile,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.personalAmolEmptySubtitle,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          TextButton(
            onPressed: onManage,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.gold,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              minimumSize: Size(44.r, 44.r),
            ),
            child: Text(
              l10n.personalAmolEmptyCta,
              style: AppTextStyles.label(context).copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
