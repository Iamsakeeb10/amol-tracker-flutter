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
import '../../../../providers/date_provider.dart';
import '../../../../providers/personal_amol_home_lock_provider.dart';
import '../../../../providers/personal_amol_pending_provider.dart';
import '../../../../providers/personal_amol_provider.dart';
import '../../../history/presentation/screens/day_detail_screen.dart';
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
  required WidgetRef ref,
  required BuildContext context,
}) {
  final l10n = AppLocalizations.of(context)!;
  final readOnly = ref.watch(personalAmolHomeLockedProvider(uid));
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
      child: _PersonalAmolHeader(
        uid: uid,
        l10n: l10n,
        showEdit: readOnly,
      ),
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

class _PersonalAmolHeader extends ConsumerWidget {
  const _PersonalAmolHeader({
    required this.uid,
    required this.l10n,
    required this.showEdit,
  });

  final String uid;
  final AppLocalizations l10n;
  final bool showEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.personalAmolSectionTitle,
            style: AppTextStyles.headlineMedium(context),
          ),
        ),
        if (showEdit) ...[
          _headerIconButton(
            icon: Icons.edit_outlined,
            tooltip: l10n.personalAmolEditToday,
            onTap: () {
              final todayHijri = ref.read(currentHijriDateProvider);
              context.push(
                AppRoutes.dayDetailPath(todayHijri),
                extra: DayDetailMode.personal,
              );
            },
          ),
          SizedBox(width: 8.w),
        ],
        _headerIconButton(
          icon: Icons.add,
          tooltip: l10n.personalAmolAddLabel,
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
        SizedBox(width: 8.w),
        _MoreMenuButton(
          l10n: l10n,
          onInfo: () => showPersonalAmolInfoDialog(context),
          onManage: () {
            AnalyticsService.instance.logPersonalAmolScreenOpened();
            context.push(AppRoutes.personalAmolList);
          },
        ),
      ],
    );
  }

  /// Matches community [HomeSubmittedAmalIconButton] size/gap (40×40, 8.w).
  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 40.r,
          height: 40.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.goldCard,
            border: Border.all(color: AppColors.goldBorder),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: AppColors.gold, size: 20.r),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }
}

enum _PersonalAmolMoreAction { info, manage }

/// Overflow menu for secondary personal-amol actions (info + manage list).
class _MoreMenuButton extends StatelessWidget {
  const _MoreMenuButton({
    required this.l10n,
    required this.onInfo,
    required this.onManage,
  });

  final AppLocalizations l10n;
  final VoidCallback onInfo;
  final VoidCallback onManage;

  static const Color _menuBg = AppColors.emeraldMid;
  static const Color _menuBorder = AppColors.goldBorder;

  @override
  Widget build(BuildContext context) {
    // Opens under the icon button, with a small gap past the icon height.
    final menuOffset = Offset(0, 6.h);

    return SizedBox(
      width: 40.r,
      height: 40.r,
      child: PopupMenuButton<_PersonalAmolMoreAction>(
        tooltip: l10n.duaReaderMore,
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        offset: menuOffset,
        color: _menuBg,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: const BorderSide(color: _menuBorder, width: 1),
        ),
        onSelected: (action) {
          switch (action) {
            case _PersonalAmolMoreAction.info:
              onInfo();
            case _PersonalAmolMoreAction.manage:
              onManage();
          }
        },
        itemBuilder: (context) => [
          _menuItem(
            context,
            value: _PersonalAmolMoreAction.info,
            icon: Icons.info_outline_rounded,
            label: l10n.personalAmolInfoMenu,
          ),
          _menuItem(
            context,
            value: _PersonalAmolMoreAction.manage,
            icon: Icons.format_list_bulleted_rounded,
            label: l10n.personalAmolManage,
          ),
        ],
        child: Container(
          width: 40.r,
          height: 40.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.goldCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.goldBorder),
          ),
          child: Icon(
            Icons.more_horiz_rounded,
            color: AppColors.gold,
            size: 20.r,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<_PersonalAmolMoreAction> _menuItem(
    BuildContext context, {
    required _PersonalAmolMoreAction value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<_PersonalAmolMoreAction>(
      value: value,
      height: 44.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.goldCard,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.goldBorder),
            ),
            child: Icon(icon, color: AppColors.gold, size: 18.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
