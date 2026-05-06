import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/hijri_helper.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/streak_badge.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _sendingDua = false;
  bool _savingOwnProfile = false;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = ref.read(firestoreServiceProvider);
    final me = ref.watch(currentUserProvider).asData?.value;
    final isOwn = me?.uid == widget.userId;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.community),
        ),
        title: Text('User Profile', style: AppTextStyles.headlineMedium(context)),
      ),
      body: StreamBuilder<UserModel?>(
        stream: fs.userStream(widget.userId),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = userSnap.data;
          if (user == null) {
            return Center(
              child: Text(
                'This profile is unavailable.',
                style: AppTextStyles.bodyMedium(context),
              ),
            );
          }
          if (_nameController.text.isEmpty) {
            _nameController.text = user.name;
          }

          return FutureBuilder<_ProfileData>(
            future: _loadProfileData(fs, user.uid),
            builder: (context, dataSnap) {
              final profileData = dataSnap.data;
              final todayLog = profileData?.todayLog;
              final weekly = profileData?.weeklyLogs ?? const <AmalLogModel>[];
              final avgScore = profileData?.avgScore ?? 0;
              final todayScore = todayLog?.score ?? 0;
              final displayAnonymous = user.isAnonymousDisplay && !isOwn;
              final shownName = displayAnonymous
                  ? 'Anonymous'
                  : (user.name.trim().isEmpty ? 'Community member' : user.name.trim());

              return ListView(
                padding: EdgeInsets.fromLTRB(0, 6.h, 0, 24.h),
                children: [
                  Center(
                    child: AvatarChip(
                      initial: displayAnonymous
                          ? '🕌'
                          : (shownName.isNotEmpty ? shownName.substring(0, 1).toUpperCase() : 'A'),
                      color: displayAnonymous ? AppColors.emeraldLight : AppColors.emeraldMid,
                      size: 76,
                      ring: true,
                      fontSize: 28,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    shownName,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayMedium(context),
                  ),
                  SizedBox(height: 6.h),
                  Center(child: StreakBadge(days: user.currentStreak)),
                  SizedBox(height: 14.h),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 340.w;
                      return GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8.h,
                        crossAxisSpacing: 8.w,
                        childAspectRatio: compact ? 1.05 : 1.28,
                        children: [
                          StatCard(
                            label: 'Today',
                            value: '$todayScore',
                            sublabel: '/100',
                            prominent: true,
                          ),
                          StatCard(
                            label: 'Best',
                            value: '${user.bestStreak}',
                            sublabel: 'days',
                            prominent: true,
                          ),
                          StatCard(
                            label: 'Avg',
                            value: '$avgScore',
                            sublabel: '/100',
                            prominent: true,
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 16.h),
                  Text('Today\'s amal', style: AppTextStyles.headlineMedium(context)),
                  SizedBox(height: 8.h),
                  CardContainer(
                    child: Column(
                      children: [
                        for (var i = 0; i < kAmalFields.length; i++) ...[
                          _AmalReadOnlyRow(
                            label: kAmalFields[i].label,
                            done: (todayLog?.toggles[kAmalFields[i].id] ?? false),
                          ),
                          if (i != kAmalFields.length - 1) SizedBox(height: 8.h),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text('Last 7 days', style: AppTextStyles.headlineMedium(context)),
                  SizedBox(height: 8.h),
                  _WeeklyBars(logs: weekly),
                  SizedBox(height: 16.h),
                  if (isOwn) ...[
                    Text('Profile settings', style: AppTextStyles.headlineMedium(context)),
                    SizedBox(height: 8.h),
                    CardContainer(
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Display name'),
                          ),
                          SizedBox(height: 10.h),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Show as Anonymous in community',
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            value: user.isAnonymousDisplay,
                            onChanged: _savingOwnProfile
                                ? null
                                : (value) async {
                                    setState(() => _savingOwnProfile = true);
                                    try {
                                      await fs.updateUser(user.uid, {
                                        'isAnonymousDisplay': value,
                                      });
                                    } finally {
                                      if (mounted) setState(() => _savingOwnProfile = false);
                                    }
                                  },
                          ),
                          SizedBox(height: 8.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _savingOwnProfile
                                  ? null
                                  : () async {
                                      final trimmed = _nameController.text.trim();
                                      if (trimmed.isEmpty) return;
                                      setState(() => _savingOwnProfile = true);
                                      try {
                                        await fs.updateUser(user.uid, {'name': trimmed});
                                      } finally {
                                        if (mounted) {
                                          setState(() => _savingOwnProfile = false);
                                        }
                                      }
                                    },
                              child: Text(
                                _savingOwnProfile ? 'Saving...' : 'Save profile',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sendingDua || me == null
                            ? null
                            : () => _sendDua(context, fs, me.uid, widget.userId),
                        icon: const Text('🤲'),
                        label: Text(_sendingDua ? 'Sending...' : 'Send Dua'),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<_ProfileData> _loadProfileData(FirestoreService fs, String uid) async {
    final today = HijriHelper.todayString();
    final todayLog = await fs.getLog(uid, today);
    final weekly = await fs.getRecentLogs(uid, limit: 7);
    final avgScore = weekly.isEmpty
        ? 0
        : (weekly.map((e) => e.score).reduce((a, b) => a + b) / weekly.length).round();
    return _ProfileData(
      todayLog: todayLog,
      weeklyLogs: weekly,
      avgScore: avgScore,
    );
  }

  Future<void> _sendDua(
    BuildContext context,
    FirestoreService fs,
    String senderUid,
    String recipientUid,
  ) async {
    setState(() => _sendingDua = true);
    try {
      final today = HijriHelper.todayString();
      final exists = await fs.hasSentDuaToday(
        senderUid: senderUid,
        recipientUid: recipientUid,
        hijriDate: today,
      );
      if (exists) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already sent a dua today')),
        );
        return;
      }
      await fs.sendDua(
        senderUid: senderUid,
        recipientUid: recipientUid,
        hijriDate: today,
        message: 'A community member sent you a dua 🤲',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dua sent ✓')),
      );
    } finally {
      if (mounted) setState(() => _sendingDua = false);
    }
  }
}

class _AmalReadOnlyRow extends StatelessWidget {
  const _AmalReadOnlyRow({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          done ? '✅' : '❌',
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: done ? AppColors.success : AppColors.danger,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.logs});

  final List<AmalLogModel> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return CardContainer(
        child: Text(
          'No recent logs available.',
          style: AppTextStyles.bodyMedium(context),
        ),
      );
    }
    final bars = logs.take(7).toList();
    return CardContainer(
      child: SizedBox(
        height: 130.h,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: bars.map((log) {
            final ratio = (log.score / 100).clamp(0.0, 1.0);
            final missed = log.score < 50;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${log.score}',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 10.sp,
                        color: missed ? AppColors.danger : AppColors.gold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      height: 80.h * ratio,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: missed
                              ? const [AppColors.danger, AppColors.dangerLight]
                              : const [AppColors.gold, AppColors.goldLight],
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      log.hijriDate.split('-').last,
                      style: AppTextStyles.bodySmall(context).copyWith(fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.todayLog,
    required this.weeklyLogs,
    required this.avgScore,
  });

  final AmalLogModel? todayLog;
  final List<AmalLogModel> weeklyLogs;
  final int avgScore;
}
