import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/personal_amol_model.dart';
import '../../../../providers/personal_amol_provider.dart';
import 'personal_amol_empty_state.dart';
import 'personal_amol_progress_row.dart';
import 'personal_amol_tile.dart';

/// Home-screen personal amol section appended after the community amol
/// section. Completions are immediate (single tap) and never touch the
/// community score, streak, or leaderboard.
class PersonalAmolSection extends ConsumerWidget {
  const PersonalAmolSection({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final amolAsync = ref.watch(activePersonalAmolProvider(uid));
    final completionsAsync = ref.watch(
      personalAmolCompletionsForTodayProvider(uid),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, ref, l10n),
        SizedBox(height: 12.h),
        amolAsync.when(
          loading: () => const PersonalAmolSectionSkeleton(),
          error: (_, _) => const SizedBox.shrink(),
          data: (amols) {
            final doneSet = (completionsAsync.value ?? const <PersonalAmolCompletion>[])
                .map((c) => c.amolId)
                .toSet();
            if (amols.isEmpty) {
              return PersonalAmolEmptyState(
                onAdd: () => context.push(AppRoutes.personalAmolCreate),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PersonalAmolProgressRow(
                  done: doneSet.length,
                  total: amols.length,
                ),
                SizedBox(height: 16.h),
                for (final amol in amols) ...[
                  PersonalAmolTile(
                    uid: uid,
                    amol: amol,
                    completed: doneSet.contains(amol.id),
                    onToggle: () =>
                        ref
                            .read(personalAmolNotifierProvider(uid).notifier)
                            .toggleComplete(amol),
                  ),
                  SizedBox(height: 8.h),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.personalAmolSectionTitle,
            style: AppTextStyles.headlineMedium(context),
          ),
        ),
        _headerIconButton(
          icon: Icons.format_list_bulleted_rounded,
          onTap: () => context.push(AppRoutes.personalAmolList),
        ),
        SizedBox(width: 10.w),
        _headerIconButton(
          icon: Icons.add,
          onTap: () => context.push(AppRoutes.personalAmolCreate),
        ),
      ],
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
