import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _isSubmitting = false;
  bool _isAnonymousDisplay = false;
  bool _notificationRequested = false;
  String _displayName = '';

  void _logOnboardingEvent(String message) {
    developer.log(message, name: 'Onboarding');
  }

  void _logOnboardingError(Object error, StackTrace stackTrace) {
    developer.log(
      'Failed to complete onboarding',
      name: 'Onboarding',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static const _slides = <_SlideData>[
    _SlideData(
      icon: Icons.calendar_month_outlined,
      title: 'Build a daily habit',
      body:
          'Track 9 daily amal — fard, sunnah, azkar, Quran. Tiny, consistent steps.',
      kind: _SlideKind.simple,
    ),
    _SlideData(
      icon: Icons.local_fire_department_rounded,
      title: 'Streaks keep you going',
      body: "Don't break the chain. Hit 7, 30, 100 days — earn your khair.",
      kind: _SlideKind.streaks,
    ),
    _SlideData(
      icon: Icons.group_outlined,
      title: 'Set up your profile',
      body: 'Set your name and privacy before joining the community.',
      kind: _SlideKind.setup,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final authUser = FirebaseAuth.instance.currentUser;
    _displayName = authUser?.displayName?.trim().isNotEmpty == true
        ? authUser!.displayName!.trim()
        : 'Anonymous';
    _isAnonymousDisplay = authUser?.isAnonymous ?? false;
  }

  Future<void> _next() async {
    if (_index < _slides.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    _logOnboardingEvent('Get started button pressed');
    await _completeOnboarding();
  }

  Future<void> _skip() {
    _logOnboardingEvent('Skip button pressed');
    return _completeOnboarding();
  }

  Future<void> _requestNotificationPermission() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final ios = plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    await android?.requestNotificationsPermission();
    if (mounted) {
      setState(() => _notificationRequested = true);
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isSubmitting) return;
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    final fallbackName = authUser.isAnonymous ? 'Anonymous' : 'User';
    final resolvedName = _displayName.trim().isNotEmpty
        ? _displayName.trim()
        : (authUser.displayName?.trim().isNotEmpty == true
              ? authUser.displayName!.trim()
              : fallbackName);

    setState(() => _isSubmitting = true);
    try {
      _logOnboardingEvent('Creating user doc for uid=${authUser.uid}');
      await ref
          .read(firestoreServiceProvider)
          .createUser(
            UserModel(
              uid: authUser.uid,
              name: resolvedName,
              email: authUser.email ?? '',
              photoUrl: authUser.photoURL ?? '',
              createdAt: DateTime.now(),
              currentStreak: 0,
              bestStreak: 0,
              streakFreezeUsed: false,
              lastLogDate: '',
              isAnonymousDisplay: _isAnonymousDisplay,
              badges: const <String>[],
            ),
          );
      _logOnboardingEvent('User doc created successfully');
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e, st) {
      _logOnboardingError(e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not complete onboarding: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isSubmitting ? null : _skip,
              child: Text(
                'Skip',
                style: AppTextStyles.button(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _SlideContent(
                slide: _slides[i],
                displayName: _displayName,
                isAnonymousDisplay: _isAnonymousDisplay,
                notificationRequested: _notificationRequested,
                onNameChanged: (value) => _displayName = value,
                onAnonymousChanged: (value) {
                  setState(() => _isAnonymousDisplay = value);
                },
                onRequestNotification: _requestNotificationPermission,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                height: 6.r,
                width: active ? 22.w : 6.r,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.gold
                      : AppColors.textMuted.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(99.r),
                ),
              );
            }),
          ),
          SizedBox(height: 18.h),
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
            child: SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  _isSubmitting
                      ? 'Please wait...'
                      : (_index == _slides.length - 1 ? 'Get started' : 'Next'),
                  style: AppTextStyles.button(context).copyWith(
                    color: AppColors.emeraldDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          if (_isSubmitting) ...[
            const CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }
}

enum _SlideKind { simple, streaks, setup }

class _SlideData {
  final IconData icon;
  final String title;
  final String body;
  final _SlideKind kind;
  const _SlideData({
    required this.icon,
    required this.title,
    required this.body,
    required this.kind,
  });
}

class _SlideContent extends StatelessWidget {
  final _SlideData slide;
  final String displayName;
  final bool isAnonymousDisplay;
  final bool notificationRequested;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<bool> onAnonymousChanged;
  final VoidCallback onRequestNotification;

  const _SlideContent({
    required this.slide,
    required this.displayName,
    required this.isAnonymousDisplay,
    required this.notificationRequested,
    required this.onNameChanged,
    required this.onAnonymousChanged,
    required this.onRequestNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 140.r,
                      height: 140.r,
                      decoration: BoxDecoration(
                        color: AppColors.goldCard,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.goldBorder,
                          width: 1.r,
                        ),
                      ),
                      child: Icon(
                        slide.icon,
                        color: AppColors.goldLight,
                        size: 60.r,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    Text(
                      slide.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayMedium(context),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      slide.body,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    SizedBox(height: 22.h),
                    if (slide.kind == _SlideKind.streaks)
                      const _StreakBadgesRow(),
                    if (slide.kind == _SlideKind.setup)
                      _SetupSlide(
                        displayName: displayName,
                        isAnonymousDisplay: isAnonymousDisplay,
                        notificationRequested: notificationRequested,
                        onNameChanged: onNameChanged,
                        onAnonymousChanged: onAnonymousChanged,
                        onRequestNotification: onRequestNotification,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StreakBadgesRow extends StatelessWidget {
  const _StreakBadgesRow();
  @override
  Widget build(BuildContext context) {
    Widget pill(String label, String days) {
      return Expanded(
        child: CardContainer(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          color: AppColors.goldCard,
          borderColor: AppColors.goldBorder,
          child: Column(
            children: [
              Text(
                days,
                style: AppTextStyles.goldNumeric(
                  context,
                ).copyWith(fontSize: 22.sp),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(fontSize: 10.sp),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        children: [
          pill('Starter', '7'),
          SizedBox(width: 10.w),
          pill('Habit', '30'),
          SizedBox(width: 10.w),
          pill('Devoted', '100'),
        ],
      ),
    );
  }
}

class _SetupSlide extends StatelessWidget {
  final String displayName;
  final bool isAnonymousDisplay;
  final bool notificationRequested;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<bool> onAnonymousChanged;
  final VoidCallback onRequestNotification;

  const _SetupSlide({
    required this.displayName,
    required this.isAnonymousDisplay,
    required this.notificationRequested,
    required this.onNameChanged,
    required this.onAnonymousChanged,
    required this.onRequestNotification,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer.gold(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Display name',
            style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            initialValue: displayName,
            onChanged: onNameChanged,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.textHint),
            ),
          ),
          SizedBox(height: 12.h),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Show as Anonymous in community',
              style: AppTextStyles.bodySmall(context),
            ),
            value: isAnonymousDisplay,
            onChanged: onAnonymousChanged,
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRequestNotification,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.goldBorder),
              ),
              child: Text(
                notificationRequested
                    ? 'Notifications enabled'
                    : 'Allow notifications',
                style: AppTextStyles.button(
                  context,
                ).copyWith(color: AppColors.goldLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
