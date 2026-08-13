import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../providers/locale_provider.dart';
import '../../providers/topic_providers.dart';
import '../../models/topic_model.dart';

class TopicSelectionScreen extends ConsumerWidget {
  const TopicSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTopicsAsync = ref.watch(activeTopicsProvider);
    final locale = ref.watch(localeProvider).languageCode;
    final isBn = locale == 'bn';

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: Text(
          isBn ? 'নলেজ ব্যাটেল' : 'Knowledge Battle',
          style: AppTextStyles.headlineMedium(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: _JoinCodeFab(
              label: isBn ? 'কোড দিয়ে যোগ দিন' : 'Join with Code',
              onTap: () => context.push(AppRoutes.battleJoin),
            ),
          ),
        ],
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Subtle ambient glow, consistent with the app's emerald + gold identity.
          Positioned(
            top: -80.r,
            right: -60.r,
            child: _AmbientGlow(color: AppColors.gold, size: 220.r),
          ),
          Positioned(
            bottom: -100.r,
            left: -80.r,
            child: _AmbientGlow(color: AppColors.emeraldLight, size: 260.r),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                child: Row(
                  children: [
                    Container(
                      width: 4.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(AppRadius.sm.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      isBn ? 'টপিক নির্বাচন করুন' : 'Select a Topic',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(

                child: activeTopicsAsync.when(
                  data: (topics) {
                    if (topics.isEmpty) {
                      return _EmptyState(isBn: isBn);
                    }

                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(12.w, 4.h, 20.w, 100.h),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index];
                        return _TopicCard(
                          topic: topic,
                          locale: locale,
                          onTap: () {
                            context.push(AppRoutes.battleConfigPath(topic.id));
                          },
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 2.5.r,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.danger,
                          size: 32.r,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          isBn ? 'টপিক লোড করা যায়নি' : 'Error loading topics',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inline replacement for CardContainer — a self-contained, tappable topic
/// tile styled explicitly with AppColors (no default Material theming).
class _TopicCard extends StatelessWidget {
  final TopicModel topic;
  final String locale;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topic,
    required this.locale,
    required this.onTap,
  });

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'quran':
        return Icons.auto_stories_outlined;
      case 'hadith':
        return Icons.menu_book_outlined;
      case 'fiqh':
        return Icons.gavel_outlined;
      case 'seerah':
        return Icons.history_edu_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsText = locale == 'bn'
        ? '${topic.questionCount} টি প্রশ্ন'
        : '${topic.questionCount} questions';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        splashColor: AppColors.goldCard,
        highlightColor: AppColors.goldCard,
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardDark,
                AppColors.emeraldMid.withValues(alpha: 0.35),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
            border: Border.all(color: AppColors.cardBorder, width: 1.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.goldLight, AppColors.gold],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      blurRadius: 14.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Icon(
                  _getIconData(topic.iconName),
                  color: AppColors.emeraldDeep,
                  size: 26.r,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                topic.displayName(locale),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.goldCard,
                  borderRadius: BorderRadius.circular(AppRadius.sm.r),
                  border: Border.all(color: AppColors.goldBorder, width: 1.r),
                ),
                child: Text(
                  questionsText,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.goldLight,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
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



class _JoinCodeFab extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _JoinCodeFab({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.xl.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.goldLight, AppColors.gold],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.4),
                blurRadius: 16.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.login_rounded, color: AppColors.emeraldDeep, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                label,
                style: AppTextStyles.labelLarge(context).copyWith(
                  color: AppColors.emeraldDeep,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isBn;

  const _EmptyState({required this.isBn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder, width: 1.r),
            ),
            child: Icon(
              Icons.hourglass_empty_rounded,
              color: AppColors.textMuted,
              size: 28.r,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            isBn ? 'শীঘ্রই নতুন টপিক যোগ করা হবে।' : 'New topics coming soon.',
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}