import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/streak_badge.dart';
import '../../../../shared/widgets/toggle_row.dart';
import '../../../../l10n/app_localizations.dart';

class GroupManageScreen extends StatefulWidget {
  const GroupManageScreen({super.key});

  @override
  State<GroupManageScreen> createState() => _GroupManageScreenState();
}

class _GroupManageScreenState extends State<GroupManageScreen> {
  bool _publicLeaderboard = true;
  bool _quietHoursActive = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/friends'),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                l10n.group,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headlineMedium(context),
              ),
            ),
            SizedBox(width: 8.w),
            Pill(
              text: l10n.admin,
              color: AppColors.goldCard,
              textColor: AppColors.gold,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 4.h, 0, 24.h),
        children: [
          Text(kGroup.name, style: AppTextStyles.displayMedium(context)),
          SizedBox(height: 4.h),
          Text(kGroup.description, style: AppTextStyles.bodyMedium(context)),
          SizedBox(height: 18.h),
          SectionHeader(title: l10n.inviteCodeUpper),
          CardContainer.gold(
            child: Column(
              children: [
                Text(
                  kGroup.inviteCode,
                  style: AppTextStyles.displayLarge(context).copyWith(
                    color: AppColors.goldLight,
                    fontSize: 30.sp,
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _IconAction(
                      icon: Icons.copy_rounded,
                      label: l10n.copy,
                      onTap: () => Clipboard.setData(
                        ClipboardData(text: kGroup.inviteCode),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    _IconAction(
                      icon: Icons.share_rounded,
                      label: l10n.share,
                      onTap: () {},
                    ),
                    SizedBox(width: 12.w),
                    _IconAction(
                      icon: Icons.refresh_rounded,
                      label: l10n.refresh,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SectionHeader(title: l10n.members),
          ...kGroup.members.map(
            (m) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _MemberRow(user: m),
            ),
          ),
          SizedBox(height: 16.h),
          SectionHeader(title: l10n.groupSettings),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            child: Column(
              children: [
                ToggleRow(
                  icon: Icons.leaderboard_outlined,
                  title: l10n.publicLeaderboard,
                  subtitle: l10n.publicLeaderboardSubtitle,
                  value: _publicLeaderboard,
                  onChanged: (v) => setState(() => _publicLeaderboard = v),
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.do_not_disturb_on_outlined,
                  title: l10n.quietHoursActive,
                  subtitle: l10n.quietHoursActiveSubtitle,
                  value: _quietHoursActive,
                  onChanged: (v) => setState(() => _quietHoursActive = v),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: Icon(Icons.delete_outline, size: 20.r),
            label: Text(l10n.deleteGroup),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.emeraldMid,
        title: Text(
          AppLocalizations.of(context)!.deleteThisGroup,
          style: AppTextStyles.headlineMedium(context),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteGroupWarning,
          style: AppTextStyles.bodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: AppTextStyles.button(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: AppTextStyles.button(
                context,
              ).copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Column(
          children: [
            Icon(icon, color: AppColors.gold, size: 20.r),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(fontSize: 11.sp, color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final MockUser user;
  const _MemberRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final isYou = user.id == kFriends.first.id;
    return CardContainer(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          AvatarChip(initial: user.initial, color: user.avatarColor),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge(
                          context,
                        ).copyWith(fontSize: 14.sp),
                      ),
                    ),
                    if (isYou) ...[
                      SizedBox(width: 6.w),
                      Pill(
                        text: AppLocalizations.of(context)!.admin,
                        color: AppColors.goldCard,
                        textColor: AppColors.gold,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  AppLocalizations.of(context)!.dayStreak(user.currentStreak),
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(fontSize: 11.sp),
                ),
              ],
            ),
          ),
          if (!isYou)
            TextButton(
              onPressed: () {},
              child: Text(
                AppLocalizations.of(context)!.remove,
                style: AppTextStyles.button(
                  context,
                ).copyWith(color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}
