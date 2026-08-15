import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/amal_expansion_provider.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/amal_provider.dart';
import '../../../../providers/battle_teaser_provider.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../providers/auth_provider.dart';
import '../../../battle/providers/battle_providers.dart';
import 'home_editing_amal_sliver.dart';
import 'home_header.dart';
import 'home_reminder_card.dart';
import 'home_special_time_toggle.dart';
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
    required this.activeFieldCount,
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
  final int activeFieldCount;
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
    final user = ref.watch(currentUserProvider).asData?.value;
    final showReminder = user != null && !user.hasDismissedLoggingReminder;
    final showSpecialTime = user?.amalProfile == UserAmalProfile.female;

    // Collapse any expanded amal tile if its field disappears from the list
    // (e.g. admin removed it or the field set changed while viewing).
    ref.listen<List<AmalField>>(
      amalFieldsListProvider,
      (previous, next) {
        ref
            .read(amalExpansionProvider.notifier)
            .collapseIfMissing(next.map((f) => f.id).toSet());
      },
    );
    // Once the day's amal is submitted, tiles become read-only, so collapse.
    ref.listen<bool>(
      amalProvider(widget.uid).select((s) => s.isSubmitted),
      (previous, next) {
        if (next) ref.read(amalExpansionProvider.notifier).collapse();
      },
    );

    // Collapse-on-tap-outside is handled by a TapRegion around the expanded
    // tile (see AmalFieldTile), which reliably routes pointer-downs globally.
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
                onNotification: (_) => false,
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
                          SliverToBoxAdapter(
                            child: ValueListenableBuilder(
                              valueListenable: LocalStorageService.activeBattleCodeListenable,
                              builder: (context, box, child) {
                                final activeBattleCode = LocalStorageService.getActiveBattleCode();
                                if (activeBattleCode == null) return const SizedBox.shrink();
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 10.h),
                                  child: Material(
                                    color: AppColors.gold,
                                    borderRadius: BorderRadius.circular(12.r),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            context.push(AppRoutes.battleWaitingRoomPath(activeBattleCode));
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.fromLTRB(16.r, 20.r, 36.r, 20.r),
                                            child: Row(
                                              children: [
                                                Icon(Icons.gamepad, color: AppColors.emeraldDeep, size: 24.r),
                                                SizedBox(width: 12.w),
                                                Expanded(
                                                  child: Text(
                                                    widget.locale == 'bn' ? 'আপনার একটি নলেজ ব্যাটেল চলছে!' : 'You have an active Knowledge Battle!',
                                                    style: AppTextStyles.titleSmall(context).copyWith(
                                                      color: AppColors.emeraldDeep,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  widget.locale == 'bn' ? 'যোগ দিন' : 'Rejoin',
                                                  style: AppTextStyles.labelLarge(context).copyWith(
                                                    color: AppColors.emeraldDeep,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: 4.w),
                                                Icon(Icons.arrow_forward_ios, color: AppColors.emeraldDeep, size: 14.r),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: -12.h,
                                          right: -8.w,
                                          child: IconButton(
                                            padding: EdgeInsets.all(8.r),
                                            constraints: const BoxConstraints(),
                                            icon: Icon(Icons.close, color: AppColors.emeraldDeep.withValues(alpha: 0.6), size: 16.r),
                                            onPressed: () {
                                              try {
                                                final repo = ref.read(battleRepositoryProvider);
                                                repo.leaveBattle(code: activeBattleCode).catchError((_) {});
                                              } catch (_) {}
                                              LocalStorageService.clearActiveBattleCode();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                              total: widget.activeFieldCount,
                              score: widget.totalScore,
                              maxScore: widget.maxScore,
                              header: showSpecialTime
                                  ? const HomeSpecialTimeToggle()
                                  : null,
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                          const SliverToBoxAdapter(
                            child: HomeTopPerformers(),
                          ),

                          if (showReminder) ...[
                            SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                            SliverToBoxAdapter(
                              child: HomeReminderCard(
                                l10n: l10n,
                                onDismiss: () {
                                  ref.read(firestoreServiceProvider).dismissLoggingReminder(widget.uid);
                                },
                              ),
                            ),
                          ],
                          SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                          Consumer(
                            builder: (context, ref, _) {
                              final showTeaserAsync = ref.watch(showBattleTeaserProvider(widget.uid));
                              return showTeaserAsync.when(
                                data: (show) {
                                  if (!show) return const SliverToBoxAdapter(child: SizedBox.shrink());
                                  return SliverMainAxisGroup(
                                    slivers: [
                                      SliverToBoxAdapter(
                                        child: KnowledgeBattleBanner(
                                          l10n: l10n,
                                          locale: widget.locale,
                                          onYes: () async {
                                            await LocalStorageService.saveHasSeenBattleTeaser(true);
                                            await ref.read(firestoreServiceProvider).saveBattleInterest(
                                              uid: widget.uid,
                                              response: 'yes',
                                              locale: widget.locale,
                                            );
                                            ref.invalidate(showBattleTeaserProvider(widget.uid));
                                          },
                                          onNo: () async {
                                            await LocalStorageService.saveHasSeenBattleTeaser(true);
                                            await ref.read(firestoreServiceProvider).saveBattleInterest(
                                              uid: widget.uid,
                                              response: 'no',
                                              locale: widget.locale,
                                            );
                                            ref.invalidate(showBattleTeaserProvider(widget.uid));
                                          },
                                          onDismiss: () async {
                                            await LocalStorageService.saveHasSeenBattleTeaser(true);
                                            await ref.read(firestoreServiceProvider).saveBattleInterest(
                                              uid: widget.uid,
                                              response: 'dismissed',
                                              locale: widget.locale,
                                            );
                                            ref.invalidate(showBattleTeaserProvider(widget.uid));
                                          },
                                        ),
                                      ),
                                      SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                                    ],
                                  );
                                },
                                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                              );
                            },
                          ),
                          const HomeQuickNavSection(),
                          SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                          if (widget.isSubmitted)
                            ...buildHomeSubmittedAmalSlivers(
                              context: context,
                              uid: widget.uid,
                              fieldsAsync: widget.fieldsAsync,
                              locale: widget.locale,
                              l10n: l10n,
                              submittedLog: widget.submittedLog,
                              userProfile: user?.amalProfile ?? UserAmalProfile.unset,
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
