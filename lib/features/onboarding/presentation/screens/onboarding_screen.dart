import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
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
      body:
          "Don't break the chain. Hit 7, 30, 100 days — earn your khair.",
      kind: _SlideKind.streaks,
    ),
    _SlideData(
      icon: Icons.group_outlined,
      title: 'Pull your brothers along',
      body: 'Join with an invite code. Encourage each other every day.',
      kind: _SlideKind.invite,
    ),
  ];

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _skip() => context.go(AppRoutes.home);

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
              onPressed: _skip,
              child: Text(
                'Skip',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _SlideContent(slide: _slides[i]),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: active ? 22 : 6,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.gold
                      : AppColors.textMuted.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _index == _slides.length - 1 ? 'Get started' : 'Next',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.emeraldDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SlideKind { simple, streaks, invite }

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
  const _SlideContent({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.goldCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldBorder, width: 1),
            ),
            child: Icon(slide.icon, color: AppColors.goldLight, size: 60),
          ),
          const SizedBox(height: 28),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 10),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 22),
          if (slide.kind == _SlideKind.streaks) const _StreakBadgesRow(),
          if (slide.kind == _SlideKind.invite) const _InvitePreview(),
        ],
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: AppColors.goldCard,
          borderColor: AppColors.goldBorder,
          child: Column(
            children: [
              Text(
                days,
                style: AppTextStyles.goldNumeric.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          pill('Starter', '7'),
          const SizedBox(width: 10),
          pill('Habit', '30'),
          const SizedBox(width: 10),
          pill('Devoted', '100'),
        ],
      ),
    );
  }
}

class _InvitePreview extends StatelessWidget {
  const _InvitePreview();
  @override
  Widget build(BuildContext context) {
    return CardContainer.gold(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      child: Column(
        children: [
          Text(
            'INVITE CODE',
            style: AppTextStyles.label.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 6),
          Text(
            'BRO-447',
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.goldLight,
              fontSize: 32,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}
