import 'package:flutter/material.dart';
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
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/friends'),
        ),
        title: Row(
          children: [
            Text('Group', style: AppTextStyles.headlineMedium),
            const SizedBox(width: 8),
            const Pill(
              text: 'admin',
              color: AppColors.goldCard,
              textColor: AppColors.gold,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
        children: [
          Text(
            kGroup.name,
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 4),
          Text(kGroup.description, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 18),
          const SectionHeader(title: 'INVITE CODE'),
          CardContainer.gold(
            child: Column(
              children: [
                Text(
                  kGroup.inviteCode,
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.goldLight,
                    fontSize: 30,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _IconAction(
                      icon: Icons.copy_rounded,
                      label: 'Copy',
                      onTap: () => Clipboard.setData(
                        ClipboardData(text: kGroup.inviteCode),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _IconAction(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),
                    _IconAction(
                      icon: Icons.refresh_rounded,
                      label: 'Refresh',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'MEMBERS'),
          ...kGroup.members.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MemberRow(user: m),
              )),
          const SizedBox(height: 16),
          const SectionHeader(title: 'GROUP SETTINGS'),
          CardContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                ToggleRow(
                  icon: Icons.leaderboard_outlined,
                  title: 'Public leaderboard',
                  subtitle: 'Show ranks to all members',
                  value: _publicLeaderboard,
                  onChanged: (v) => setState(() => _publicLeaderboard = v),
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.do_not_disturb_on_outlined,
                  title: 'Quiet hours active',
                  subtitle: 'Mute notifications at night',
                  value: _quietHoursActive,
                  onChanged: (v) => setState(() => _quietHoursActive = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete group'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
          'Delete this group?',
          style: AppTextStyles.headlineMedium,
        ),
        content: Text(
          'Members will lose access. This cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Delete',
              style: AppTextStyles.button.copyWith(color: AppColors.danger),
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
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: AppColors.gold, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.gold,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          AvatarChip(initial: user.initial, color: user.avatarColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: AppTextStyles.bodyLarge.copyWith(fontSize: 14),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 6),
                      const Pill(
                        text: 'admin',
                        color: AppColors.goldCard,
                        textColor: AppColors.gold,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.currentStreak} day streak',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          if (!isYou)
            TextButton(
              onPressed: () {},
              child: Text(
                'Remove',
                style: AppTextStyles.button.copyWith(color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}
