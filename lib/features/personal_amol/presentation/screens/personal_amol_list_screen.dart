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
import '../widgets/personal_amol_create_sheet.dart';
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
: () => PersonalAmolCreateSheet.show(context, uid: uid),
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
              onAdd: () => PersonalAmolCreateSheet.show(context, uid: uid),
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
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
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
            SizedBox(width: AppSpacing.sm.w),
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
        onTap: () =>
            PersonalAmolCreateSheet.showForEdit(context, uid: uid, amol: amol),
        onEdit: () =>
            PersonalAmolCreateSheet.showForEdit(context, uid: uid, amol: amol),
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
                borderRadius: BorderRadius.circular(AppRadius.lg.r),
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
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.goldCard, AppColors.cardDark],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
            border: Border.all(color: AppColors.goldBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.gold.withValues(alpha: 0.25),
                      AppColors.gold.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.gold,
                  size: 20.r,
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              Text(
                l10n.personalAmolEmptyHeadline,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.xs.h),
              Text(
                l10n.personalAmolEmptySubtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.label(context).copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              Center(
                child: SizedBox(
                  height: 40.h,
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: Icon(Icons.add_rounded, size: 16.r),
                    label: Text(
                      l10n.personalAmolEmptyCta,
                      style: AppTextStyles.button(context).copyWith(
                        color: AppColors.emeraldDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.emeraldDeep,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg.w,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md.r),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}