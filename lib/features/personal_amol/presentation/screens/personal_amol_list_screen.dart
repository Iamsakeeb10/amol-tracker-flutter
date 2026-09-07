import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/personal_amol_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/personal_amol_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../widgets/personal_amol_tile.dart';

class PersonalAmolListScreen extends ConsumerStatefulWidget {
  const PersonalAmolListScreen({super.key});

  @override
  ConsumerState<PersonalAmolListScreen> createState() =>
      _PersonalAmolListScreenState();
}

class _PersonalAmolListScreenState
    extends ConsumerState<PersonalAmolListScreen> {
  final Set<String> _dismissedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = ref.watch(authStateProvider).asData?.value?.uid;
    if (uid == null) {
      return AppScaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final amolAsync = ref.watch(activePersonalAmolProvider(uid));
    final atCap =
        (amolAsync.value?.length ?? 0) >= AppConstants.kMaxFreePersonalAmol;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.more),
        ),
        title: Text(
          l10n.personalAmolListTitle,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: atCap
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.personalAmolCapMessage(
                        AppConstants.kMaxFreePersonalAmol,
                      ),
                    ),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            : () => context.push(AppRoutes.personalAmolCreate),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.emeraldDeep,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      body: amolAsync.when(
        loading: () => _buildShimmer(context),
        error: (_, _) => Center(
          child: Text(
            l10n.historyLoadFailed,
            style: AppTextStyles.bodyLarge(context),
          ),
        ),
        data: (amols) {
          if (amols.isEmpty) {
            return _buildEmptyState(
              context,
              l10n,
              onAdd: () => context.push(AppRoutes.personalAmolCreate),
            );
          }
          final visible = amols
              .where((a) => !_dismissedIds.contains(a.id))
              .toList();
          return RefreshIndicator(
            color: AppColors.gold,
            backgroundColor: AppColors.emeraldMid,
            onRefresh: () async {
              _dismissedIds.clear();
            },
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
              itemCount: visible.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final amol = visible[index];
                return _buildDismissible(context, l10n, uid, amol);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDismissible(
    BuildContext context,
    AppLocalizations l10n,
    String uid,
    PersonalAmolModel amol,
  ) {
    return Dismissible(
      key: ValueKey<String>('dismiss-${amol.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.delete,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
          ],
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(context, l10n),
      onDismissed: (_) async {
        setState(() => _dismissedIds.add(amol.id));
        await ref
            .read(personalAmolNotifierProvider(uid).notifier)
            .softDeleteAmol(amol.id);
      },
      child: PersonalAmolTile(
        uid: uid,
        amol: amol,
        readOnly: true,
        onTap: () => context.push(AppRoutes.personalAmolEditPath(amol.id)),
        onEdit: () => context.push(AppRoutes.personalAmolEditPath(amol.id)),
        onDelete: () => _deleteFromIcon(context, l10n, uid, amol),
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.emeraldMid,
        title: Text(
          l10n.personalAmolDeleteConfirm,
          style: AppTextStyles.headlineMedium(ctx),
        ),
        content: Text(
          l10n.personalAmolDeleteSubtitle,
          style: AppTextStyles.bodyMedium(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: AppTextStyles.button(ctx)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: AppTextStyles.button(ctx).copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteFromIcon(
    BuildContext context,
    AppLocalizations l10n,
    String uid,
    PersonalAmolModel amol,
  ) async {
    final confirmed = await _confirmDelete(context, l10n);
    if (!confirmed) return;
    setState(() => _dismissedIds.add(amol.id));
    await ref
        .read(personalAmolNotifierProvider(uid).notifier)
        .softDeleteAmol(amol.id);
  }

  Widget _buildShimmer(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Shimmer.fromColors(
        baseColor: AppColors.cardDark,
        highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
        child: Column(
          children: List.generate(
            4,
            (_) => Container(
              height: 72.h,
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n, {
    required VoidCallback onAdd,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88.r,
              height: 88.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: AppColors.gold,
                size: 36.r,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.personalAmolEmptyHeadline,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium(context),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.personalAmolEmptySubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  l10n.personalAmolEmptyCta,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.emeraldDeep,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
