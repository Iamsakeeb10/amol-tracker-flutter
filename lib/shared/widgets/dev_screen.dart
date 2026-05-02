import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import 'app_scaffold.dart';
import 'card_container.dart';
import 'streak_freeze_modal.dart';

class DevScreen extends StatelessWidget {
  const DevScreen({super.key});

  static const _entries = <_DevEntry>[
    _DevEntry('S-00', 'Sign In', AppRoutes.signIn),
    _DevEntry('S-01', 'Onboarding', AppRoutes.onboarding),
    _DevEntry('S-02', 'Home', AppRoutes.home),
    _DevEntry('S-03', 'Leaderboard', AppRoutes.leaderboard),
    _DevEntry('S-04', 'History', AppRoutes.history),
    _DevEntry('S-05', 'Friends', AppRoutes.friends),
    _DevEntry('S-06', 'Invite', AppRoutes.invite),
    _DevEntry('S-07', 'Notifications', AppRoutes.notifications),
    _DevEntry('S-08', 'Profile', AppRoutes.profile),
    _DevEntry('S-09', 'Settings', AppRoutes.settings),
    _DevEntry('S-10', 'Day Complete', AppRoutes.dayComplete),
    _DevEntry('S-11', 'Group Sheet', AppRoutes.groupSheet),
    _DevEntry('S-12', 'Friend Profile', '${AppRoutes.friendProfile}/u1'),
    _DevEntry('S-13', 'Day Detail', AppRoutes.dayDetail),
    _DevEntry('S-14', 'Group Manage', AppRoutes.groupManage),
    _DevEntry('S-15', 'Empty State', AppRoutes.emptyState),
    _DevEntry('S-16', 'Streak Freeze (modal)', '__modal_freeze__'),
    _DevEntry('S-17', 'Quiet Hours', AppRoutes.quietHours),
    _DevEntry('—', 'More Hub', AppRoutes.more),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text('Dev Menu', style: AppTextStyles.headlineMedium(context)),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        children: [
          Text(
            'Tap a screen to jump to it (UI testing)',
            style: AppTextStyles.bodyMedium(context),
          ),
          SizedBox(height: AppSpacing.md.h),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4,
            children: [
              for (final e in _entries)
                CardContainer(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  color: AppColors.goldCard,
                  borderColor: AppColors.goldBorder,
                  onTap: () {
                    if (e.path == '__modal_freeze__') {
                      StreakFreezeModal.show(context);
                    } else {
                      context.go(e.path);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        e.id,
                        style: AppTextStyles.label(context).copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        e.label,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DevEntry {
  final String id;
  final String label;
  final String path;
  const _DevEntry(this.id, this.label, this.path);
}
