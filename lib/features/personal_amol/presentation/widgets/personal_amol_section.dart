import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/personal_amol_schedule.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/personal_amol_model.dart';
import '../../../../providers/personal_amol_pending_provider.dart';
import '../../../../providers/personal_amol_provider.dart';
import 'personal_amol_create_sheet.dart';
import 'personal_amol_details_dialog.dart';
import 'personal_amol_empty_state.dart';
import 'personal_amol_info_dialog.dart';
import 'personal_amol_progress_row.dart';
import 'personal_amol_tile.dart';

/// Home-screen personal amol slivers appended after the community amol
/// section. Mirrors [buildHomeAmalFieldSlivers]: header/progress as
/// [SliverToBoxAdapter]s and due tiles as a virtualized [SliverList.builder]
/// so scrolling stays as smooth as the community list.
///
/// Edits (toggle/+/−) stage into `personalAmolPendingProvider` and only
/// persist to Firestore when the shared save FAB is pressed — never in
/// per-tap writes, and never into the community score, streak, or leaderboard.
List<Widget> buildPersonalAmolSlivers({
  required String uid,
  required bool readOnly,
  required WidgetRef ref,
  required BuildContext context,
}) {
  final l10n = AppLocalizations.of(context)!;
  final amolAsync = ref.watch(activePersonalAmolProvider(uid));
  final completionsAsync = ref.watch(
    personalAmolCompletionsForTodayProvider(uid),
  );
  // Only rebuild when staged counts change (not isSaving / baseline churn).
  final staged = ref.watch(
    personalAmolPendingProvider(uid).select((s) => s.staged),
  );
  final pendingNotifier = ref.read(personalAmolPendingProvider(uid).notifier);

  final slivers = <Widget>[
    SliverToBoxAdapter(
      child: _PersonalAmolHeader(uid: uid, l10n: l10n),
    ),
    // Match the previous Column gap under the header.
    SliverToBoxAdapter(child: SizedBox(height: 12.h)),
  ];

  return amolAsync.when(
    loading: () => [
      ...slivers,
      const SliverToBoxAdapter(child: PersonalAmolSectionSkeleton()),
    ],
    error: (_, _) => [
      ...slivers,
      const SliverToBoxAdapter(child: SizedBox.shrink()),
    ],
    data: (amols) {
      final completions =
          completionsAsync.value ?? const <PersonalAmolCompletion>[];
      // Saved (Firestore) counts for today.
      final counts = <String, int>{};
      for (final c in completions) {
        counts[c.amolId] = (counts[c.amolId] ?? 0) + 1;
      }
      // Overlay the staged edits: anything the user changed but hasn't
      // saved yet shows immediately without any network write.
      final shown = <String, int>{
        ...counts,
        ...staged,
      };

      if (amols.isEmpty) {
        return [
          ...slivers,
          SliverToBoxAdapter(
            child: PersonalAmolEmptyState(
              onAdd: () {
                AnalyticsService.instance.logPersonalAmolCreateSheetOpened(
                  entryPoint: 'empty_state',
                );
                PersonalAmolCreateSheet.show(
                  context,
                  uid: uid,
                  entryPoint: 'empty_state',
                );
              },
            ),
          ),
        ];
      }

      final due = amols.where(personalAmolScheduledToday).toList();
      if (due.isEmpty) {
        return [
          ...slivers,
          const SliverToBoxAdapter(child: _NoneDueToday()),
        ];
      }

      final done = due
          .where((a) {
            final target = a.type == PersonalAmolType.count ? a.target : 1;
            return (shown[a.id] ?? 0) >= target;
          })
          .length;

      return [
        ...slivers,
        SliverToBoxAdapter(
          child: PersonalAmolProgressRow(
            done: done,
            total: due.length,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
        SliverList.builder(
          addAutomaticKeepAlives: false,
          itemCount: due.length,
          itemBuilder: (context, index) {
            final amol = due[index];
            final doneCount = shown[amol.id] ?? 0;
            final target =
                amol.type == PersonalAmolType.count ? amol.target : 1;
            return Padding(
              key: ValueKey(amol.id),
              padding: EdgeInsets.only(bottom: 8.h),
              child: PersonalAmolTile(
                uid: uid,
                amol: amol,
                completed: doneCount >= target,
                doneCount: doneCount,
                onTap: () => showPersonalAmolDetailsDialog(
                  context,
                  uid: uid,
                  amol: amol,
                  doneCount: doneCount,
                ),
                onToggle: (!readOnly && amol.type == PersonalAmolType.toggle)
                    ? () => pendingNotifier.toggle(amol)
                    : null,
                onPlus: (!readOnly && amol.type == PersonalAmolType.count)
                    ? () => pendingNotifier.plus(amol)
                    : null,
                onMinus: (!readOnly && amol.type == PersonalAmolType.count)
                    ? () => pendingNotifier.minus(amol)
                    : null,
              ),
            );
          },
        ),
      ];
    },
  );
}

class _PersonalAmolHeader extends StatelessWidget {
  const _PersonalAmolHeader({
    required this.uid,
    required this.l10n,
  });

  final String uid;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.personalAmolSectionTitle,
            style: AppTextStyles.headlineMedium(context),
          ),
        ),
        _headerIconButton(
          icon: Icons.info_outline_rounded,
          onTap: () => showPersonalAmolInfoDialog(context),
        ),
        SizedBox(width: 10.w),
        _headerIconButton(
          icon: Icons.format_list_bulleted_rounded,
          onTap: () {
            AnalyticsService.instance.logPersonalAmolScreenOpened();
            context.push(AppRoutes.personalAmolList);
          },
        ),
        SizedBox(width: 10.w),
        _headerIconButton(
          icon: Icons.add,
          onTap: () {
            AnalyticsService.instance.logPersonalAmolCreateSheetOpened(
              entryPoint: 'home_add',
            );
            PersonalAmolCreateSheet.show(
              context,
              uid: uid,
              entryPoint: 'home_add',
            );
          },
        ),
      ],
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    // Use a 44×44 tap target (WCAG minimum) with centred visual content.
    // Material + InkWell gives ripple feedback inside the clipped area.
    return SizedBox(
      width: 44.r,
      height: 44.r,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Center(
            child: Container(
              width: 36.r,
              height: 36.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Icon(icon, color: AppColors.gold, size: 22.r),
            ),
          ),
        ),
      ),
    );
  }
}

class PersonalAmolSectionSkeleton extends StatelessWidget {
  const PersonalAmolSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
      child: Column(
        children: [
          Container(height: 56.h, decoration: _box()),
          SizedBox(height: 8.h),
          Container(height: 56.h, decoration: _box()),
        ],
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      );
}

/// Shown when the user has personal amols, but none of them are scheduled on
/// the current Hijri day.
class _NoneDueToday extends StatelessWidget {
  const _NoneDueToday();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_busy,
            color: AppColors.textMuted,
            size: 20.r,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              l10n.personalAmolNoneDueToday,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
