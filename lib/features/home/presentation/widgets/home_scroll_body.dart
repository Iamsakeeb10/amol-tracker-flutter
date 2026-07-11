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

class HomeScrollBody extends ConsumerStatefulWidget {
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
    required this.onRefreshAll,
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
  final int? streak;
  final AmalLogModel? submittedLog;
  final bool showSaveFab;
  final Future<void> Function() onRefreshAll;
  final Future<void> Function(AmalLogModel log) onEditTodayAmal;
  final Future<void> Function() onRetryFields;

  @override
  ConsumerState<HomeScrollBody> createState() => _HomeScrollBodyState();
}

class _HomeScrollBodyState extends ConsumerState<HomeScrollBody> {
  final ScrollController _scrollController = ScrollController();
  bool _showBottomFade = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;

    final shouldShowBottomFade = offset < maxScroll;

    if (shouldShowBottomFade != _showBottomFade) {
      setState(() {
        _showBottomFade = shouldShowBottomFade;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
          child: HomeHeader(streak: widget.streak, uid: widget.uid),
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  _onScroll();
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: widget.onRefreshAll,
                  color: AppColors.gold,
                  backgroundColor: AppColors.emeraldMid,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        20.w,
                        0,
                        20.w,
                        widget.showSaveFab ? 112.h : 96.h,
                      ),
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          if (widget.offline)
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
                          if (widget.amalError != null) ...[
                            SliverToBoxAdapter(
                              child: Text(
                                widget.amalError!,
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
                              done: widget.doneCount,
                              total: widget.fields.length,
                              score: widget.totalScore,
                              maxScore: widget.maxScore,
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                          const SliverToBoxAdapter(
                            child: HomeTopPerformers(),
                          ),
                          if (widget.isNewUser) ...[
                            SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                            SliverToBoxAdapter(
                                child: HomeWelcomeCard(l10n: l10n)),
                          ],
                          SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                          if (widget.isSubmitted)
                            ...buildHomeSubmittedAmalSlivers(
                              context: context,
                              uid: widget.uid,
                              fieldsAsync: widget.fieldsAsync,
                              locale: widget.locale,
                              l10n: l10n,
                              submittedLog: widget.submittedLog,
                              onRetryFields: widget.onRetryFields,
                              onEditTodayAmal: widget.onEditTodayAmal,
                            )
                          else
                            ...buildHomeEditingAmalSlivers(
                              context: context,
                              ref: ref,
                              uid: widget.uid,
                              fieldsAsync: widget.fieldsAsync,
                              locale: widget.locale,
                              l10n: l10n,
                              isAmalLoading: widget.isAmalLoading,
                              hasAnyDone: widget.hasAnyDone,
                              onRetryFields: widget.onRetryFields,
                            ),
                          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                          const HomeQuickNavSection(),
                        ],
                      ),
                    ),
                    ],
                  ),
                ),
              ),
              // Bottom fade gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showBottomFade ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    height: 30.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.emeraldDeep,
                          AppColors.emeraldDeep.withValues(alpha: 0.8),
                          AppColors.emeraldDeep.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
