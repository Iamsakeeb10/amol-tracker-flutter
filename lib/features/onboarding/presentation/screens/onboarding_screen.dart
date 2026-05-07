import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  final ValueNotifier<int> _pageIndexNotifier = ValueNotifier<int>(0);
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

  List<_SlideData> _slides(AppLocalizations l10n) => <_SlideData>[
    _SlideData(
      icon: Icons.calendar_month_outlined,
      title: l10n.buildDailyHabitTitle,
      body: l10n.buildDailyHabitBody,
      kind: _SlideKind.simple,
    ),
    _SlideData(
      icon: Icons.local_fire_department_rounded,
      title: l10n.streaksKeepYouGoingTitle,
      body: l10n.streaksKeepYouGoingBody,
      kind: _SlideKind.streaks,
    ),
    _SlideData(
      icon: Icons.group_outlined,
      title: l10n.setupProfileTitle,
      body: l10n.setupProfileBody,
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
    final slides = _slides(AppLocalizations.of(context)!);
    if (_pageIndexNotifier.value < slides.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 180),
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
    await NotificationService.instance.initialize();
    await NotificationService.instance.scheduleAll();
    if (mounted) {
      setState(() => _notificationRequested = true);
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isSubmitting) return;
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    final l10n = AppLocalizations.of(context)!;
    final fallbackName = authUser.isAnonymous ? l10n.anonymous : l10n.user;
    final resolvedName = _displayName.trim().isNotEmpty
        ? _displayName.trim()
        : (authUser.displayName?.trim().isNotEmpty == true
              ? authUser.displayName!.trim()
              : fallbackName);

    setState(() => _isSubmitting = true);
    final userModel = UserModel(
      uid: authUser.uid,
      name: resolvedName,
      email: authUser.email ?? '',
      photoUrl: authUser.photoURL ?? '',
      createdAt: DateTime.now(),
      currentStreak: 0,
      bestStreak: 0,
      streakFreezeUsed: false,
      streakFreezeWeekKey: '',
      lastLogDate: '',
      isAnonymousDisplay: _isAnonymousDisplay,
      badges: const <String>[],
    );

    if (!mounted) return;
    context.go(AppRoutes.home);

    // Keep navigation snappy by moving network setup off the tap path.
    unawaited(_persistOnboardingData(userModel));
  }

  Future<void> _persistOnboardingData(UserModel user) async {
    try {
      _logOnboardingEvent('Creating user doc for uid=${user.uid}');
      await ref.read(firestoreServiceProvider).createUser(user);
      _logOnboardingEvent('User doc created successfully');
      await NotificationService.instance.syncFcmTokenNow();
      _logOnboardingEvent('FCM token synced after onboarding');
    } catch (e, st) {
      _logOnboardingError(e, st);
    }
  }

  String _buttonLabel(int slideCount, AppLocalizations l10n) {
    final isLastPage = _pageIndexNotifier.value == slideCount - 1;
    return isLastPage ? l10n.getStarted : l10n.next;
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slides = _slides(l10n);
    final slidePages = List<Widget>.generate(
      slides.length,
      (i) => _SlideContent(
        slide: slides[i],
        displayName: _displayName,
        isAnonymousDisplay: _isAnonymousDisplay,
        notificationRequested: _notificationRequested,
        onNameChanged: (value) => _displayName = value,
        onAnonymousChanged: (value) {
          setState(() => _isAnonymousDisplay = value);
        },
        onRequestNotification: _requestNotificationPermission,
      ),
    );
    return AppScaffold(
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isSubmitting ? null : _skip,
              child: Text(
                l10n.skip,
                style: AppTextStyles.button(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              allowImplicitScrolling: true,
              onPageChanged: (i) => _pageIndexNotifier.value = i,
              children: slidePages,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder<int>(
                valueListenable: _pageIndexNotifier,
                builder: (_, pageIndex, __) {
                  return Row(
                    children: List.generate(slides.length, (i) {
                      final active = i == pageIndex;
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
                  );
                },
              ),
            ],
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
                child: ValueListenableBuilder<int>(
                  valueListenable: _pageIndexNotifier,
                  builder: (_, __, ___) {
                    if (_isSubmitting) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16.r,
                            height: 16.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.emeraldDeep,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            l10n.pleaseWait,
                            style: AppTextStyles.button(context).copyWith(
                              color: AppColors.emeraldDeep,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    }
                    return Text(
                      _buttonLabel(slides.length, l10n),
                      style: AppTextStyles.button(context).copyWith(
                        color: AppColors.emeraldDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
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
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
          pill(AppLocalizations.of(context)!.starter, '7'),
          SizedBox(width: 10.w),
          pill(AppLocalizations.of(context)!.habit, '30'),
          SizedBox(width: 10.w),
          pill(AppLocalizations.of(context)!.devoted, '100'),
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
            AppLocalizations.of(context)!.displayName,
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
              hintText: AppLocalizations.of(context)!.yourName,
              hintStyle: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.textHint),
            ),
          ),
          SizedBox(height: 12.h),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppLocalizations.of(context)!.showAnonymousCommunity,
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
                    ? AppLocalizations.of(context)!.notificationsEnabled
                    : AppLocalizations.of(context)!.allowNotifications,
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
