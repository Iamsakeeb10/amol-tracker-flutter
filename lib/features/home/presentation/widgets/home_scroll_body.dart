import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/amal_fields.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../shared/widgets/card_container.dart';
import 'home_editing_amal_sliver.dart';
import 'home_header.dart';
import 'home_progress_card.dart';
import 'home_quick_nav_section.dart';
import 'home_submitted_amal_sliver.dart';
import 'home_welcome_card.dart';
import 'home_widgets.dart';

class HomeScrollBody extends ConsumerWidget {
  const HomeScrollBody({
    super.key,
    required this.uid,
    required this.fieldsAsync,
    required this.fields,
    required this.locale,
    required this.offline,
    required this.amalError,
    required this.doneCount,
    required this.totalScore,
    required this.maxScore,
    required this.isSubmitted,
    required this.isAmalLoading,
    required this.hasAnyDone,
    required this.isNewUser,
    required this.streak,
    required this.submittedLog,
    required this.showSaveFab,
    required this.onEditTodayAmal,
    required this.onRetryFields,
  });

  final String uid;
  final AsyncValue<List<AmalField>> fieldsAsync;
  final List<AmalField> fields;
  final String locale;
  final bool offline;
  final String? amalError;
  final int doneCount;
  final int totalScore;
  final int maxScore;
  final bool isSubmitted;
  final bool isAmalLoading;
  final bool hasAnyDone;
  final bool isNewUser;
  final int streak;
  final AmalLogModel? submittedLog;
  final bool showSaveFab;
  final Future<void> Function(AmalLogModel log) onEditTodayAmal;
  final Future<void> Function() onRetryFields;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
          child: HomeHeader(streak: streak),
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20.w,
                  0,
                  20.w,
                  showSaveFab ? 112.h : 96.h,
                ),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    if (offline)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: CardContainer(
                            color: HomeUiColors.offlineBannerBg,
                            borderColor: HomeUiColors.offlineBannerBorder,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.wifi_off,
                                  color: AppColors.warning,
                                  size: 18.r,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    l10n.homeOfflineSyncMessage,
                                    style: AppTextStyles.bodySmall(context)
                                        .copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (amalError != null) ...[
                      SliverToBoxAdapter(
                        child: Text(
                          amalError!,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.danger,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: 8.h)),
                    ],
                    SliverToBoxAdapter(
                      child: HomeProgressCard(
                        done: doneCount,
                        total: fields.length,
                        score: totalScore,
                        maxScore: maxScore,
                      ),
                    ),
                    if (isNewUser) ...[
                      SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                      SliverToBoxAdapter(child: HomeWelcomeCard(l10n: l10n)),
                    ],
                    SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                    if (isSubmitted)
                      ...buildHomeSubmittedAmalSlivers(
                        context: context,
                        uid: uid,
                        fieldsAsync: fieldsAsync,
                        locale: locale,
                        l10n: l10n,
                        submittedLog: submittedLog,
                        onRetryFields: onRetryFields,
                        onEditTodayAmal: onEditTodayAmal,
                      )
                    else
                      ...buildHomeEditingAmalSlivers(
                        context: context,
                        ref: ref,
                        uid: uid,
                        fieldsAsync: fieldsAsync,
                        locale: locale,
                        l10n: l10n,
                        isAmalLoading: isAmalLoading,
                        hasAnyDone: hasAnyDone,
                        onRetryFields: onRetryFields,
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                    const HomeQuickNavSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
