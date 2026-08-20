import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/hijri_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/activity_feed_item_model.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/amal_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_provider.dart';
import '../../../../providers/history_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/bottom_tab_back_button.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/community_row_card.dart';
import '../../../../shared/widgets/section_header.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _headerHorizontalController;
  late final ScrollController _verticalController;
  late final TextEditingController _searchController;
  final Map<String, ScrollController> _rowHorizontalControllers = {};
  bool _isSyncingHorizontal = false;
  double _horizontalOffset = 0;
  late final TabController _tabController;
  bool _isSheetTabActive = true;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenViewed('community');
    AnalyticsService.instance.logCommunityOpened();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _headerHorizontalController = ScrollController();
    _headerHorizontalController.addListener(
      () => _syncHorizontalOffsets(_headerHorizontalController),
    );
    _verticalController = ScrollController()..addListener(_onVerticalScroll);
    _searchController = TextEditingController();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() => _isSheetTabActive = _tabController.index == 0);
    if (_tabController.index == 1) {
      AnalyticsService.instance.logActivityFeedOpened();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _verticalController
      ..removeListener(_onVerticalScroll)
      ..dispose();
    _headerHorizontalController.dispose();
    for (final controller in _rowHorizontalControllers.values) {
      controller.dispose();
    }
    _rowHorizontalControllers.clear();
    super.dispose();
  }

  void _onVerticalScroll() {
    if (!_verticalController.hasClients) return;
    final max = _verticalController.position.maxScrollExtent;
    final cur = _verticalController.offset;
    if (max - cur < 180) {
      ref.read(communitySheetProvider.notifier).loadMore();
    }
  }

  ScrollController _controllerForRow(String key) {
    return _rowHorizontalControllers.putIfAbsent(key, () {
      final controller = ScrollController(
        initialScrollOffset: _horizontalOffset,
      );
      controller.addListener(() => _syncHorizontalOffsets(controller));
      return controller;
    });
  }

  void _syncHorizontalOffsets(ScrollController source) {
    if (_isSyncingHorizontal || source.positions.length != 1) return;
    _isSyncingHorizontal = true;
    try {
      _horizontalOffset = source.offset;
      final allControllers = <ScrollController>[
        _headerHorizontalController,
        ..._rowHorizontalControllers.values,
      ];
      for (final controller in allControllers) {
        if (identical(controller, source) || controller.positions.length != 1) {
          continue;
        }
        final max = controller.position.maxScrollExtent;
        final nextOffset = _horizontalOffset.clamp(0.0, max);
        if ((controller.offset - nextOffset).abs() > 0.5) {
          controller.jumpTo(nextOffset);
        }
      }
    } catch (e) {
      debugPrint('Sync offset error: $e');
    } finally {
      _isSyncingHorizontal = false;
    }
  }

  void _cleanupStaleRowControllers(Iterable<String> activeKeys) {
    final active = activeKeys.toSet();
    final stale = _rowHorizontalControllers.keys
        .where((k) => !active.contains(k))
        .toList();
    for (final key in stale) {
      _rowHorizontalControllers.remove(key)?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final fieldsAsync = ref.watch(amalFieldsProvider);
    final fields = ref.watch(amalFieldsListProvider);
    final state = ref.watch(communitySheetProvider);
    final notifier = ref.read(communitySheetProvider.notifier);
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final connectivity = ref.watch(connectivityListProvider);
    final dates = ref.watch(communityRecentDatesProvider);
    final accountCreatedHijri = ref.watch(communityAccountCreatedHijriProvider);
    final isPreAccountDate =
        accountCreatedHijri != null &&
        state.selectedDate.compareTo(accountCreatedHijri) < 0;

    final ownLogAsync = currentUser != null
        ? ref.watch(
            dayDetailLogProvider(
              DayLogKey(uid: currentUser.uid, hijriDate: state.selectedDate),
            ),
          )
        : null;
    final fetchedOwnRow = ownLogAsync?.value;

    var ownRow = state.ownRow(currentUser?.uid);
    if (ownRow == null && fetchedOwnRow != null) {
      ownRow = fetchedOwnRow;
    } else if (ownRow != null && fetchedOwnRow != null) {
      if (fetchedOwnRow.editCount > ownRow.editCount) {
        ownRow = fetchedOwnRow;
      }
    }

    final otherRows = state.filteredRowsExcludingUid(currentUser?.uid);
    final ownPlaceholder = currentUser == null
        ? null
        : _buildOwnPlaceholder(
            currentUser.uid,
            currentUser.name,
            state.selectedDate,
            fields,
          );

    ref.listen(communitySheetProvider.select((s) => s.searchQuery), (_, query) {
      if (_searchController.text != query) {
        _searchController.value = TextEditingValue(
          text: query,
          selection: TextSelection.collapsed(offset: query.length),
        );
      }
    });

    final activeRowKeys = <String>[
      if (ownRow != null || ownPlaceholder != null)
        'own-${currentUser?.uid ?? 'me'}',
      ...otherRows.map((row) => 'row-${row.uid}'),
    ];
    _cleanupStaleRowControllers(activeRowKeys);

    return AppScaffold(
      handleExitBack: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const BottomTabBackButton(),
              Expanded(
                child: AnimatedOpacity(
                  opacity: _isFullScreen ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: _isFullScreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.communityUpper,
                          style: AppTextStyles.label(
                            context,
                          ).copyWith(color: AppColors.gold),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          l10n.community,
                          style: AppTextStyles.displayMedium(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: _isSheetTabActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_isSheetTabActive,
                  child: IconButton(
                    icon: Icon(
                      Icons.fullscreen_rounded,
                      color: AppColors.textSecondary,
                      size: 24.r,
                    ),
                    onPressed: () {
                      setState(() => _isFullScreen = true);
                      Navigator.of(context, rootNavigator: true)
                          .push(
                            PageRouteBuilder(
                              fullscreenDialog: true,
                              transitionDuration: const Duration(
                                milliseconds: 320,
                              ),
                              reverseTransitionDuration: const Duration(
                                milliseconds: 280,
                              ),
                              pageBuilder:
                                  (ctx, animation, secondaryAnimation) =>
                                      const _CommunitySheetFullScreen(),
                              transitionsBuilder:
                                  (ctx, animation, secondaryAnimation, child) {
                                    final tween =
                                        Tween(
                                          begin: const Offset(0, 1),
                                          end: Offset.zero,
                                        ).chain(
                                          CurveTween(
                                            curve: Curves.easeOutCubic,
                                          ),
                                        );
                                    return SlideTransition(
                                      position: animation.drive(tween),
                                      child: child,
                                    );
                                  },
                            ),
                          )
                          .then((_) {
                            if (mounted) setState(() => _isFullScreen = false);
                          });
                    },
                    tooltip: 'Full screen',
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textSecondary,
                  size: 22.r,
                ),
                onPressed: () {
                  ref.read(communitySheetProvider.notifier).refresh();
                  ref.invalidate(activityFeedProvider);
                },
                tooltip: l10n.refresh,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(2.r),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(AppRadius.md.r),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.goldCard,
                borderRadius: BorderRadius.circular((AppRadius.md - 2).r),
                border: Border.all(color: AppColors.goldBorder),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              splashBorderRadius: BorderRadius.circular(AppRadius.md.r),
              labelColor: AppColors.goldLight,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.bodySmall(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTextStyles.bodySmall(context),
              tabs: [
                Tab(text: l10n.sheet, height: 40.h),
                Tab(text: l10n.feed, height: 40.h),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: IndexedStack(
              index: _tabController.index,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (connectivity.asData?.value.any(
                          (r) => r == ConnectivityResult.none,
                        ) ??
                        false)
                      Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: CardContainer(
                          color: AppColors.warningLight.withValues(alpha: 0.35),
                          borderColor: AppColors.warning.withValues(alpha: 0.5),
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
                                  l10n.offlineShowingLatest,
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
                    SectionHeader(
                      title: l10n.date,
                      trailingText: HijriHelper.displayFromStorage(
                        state.selectedDate,
                        languageCode: locale,
                      ),
                    ),
                    _DateTabsRow(
                      options: dates,
                      selectedDate: state.selectedDate,
                      onTapDate: notifier.selectDate,
                      locale: locale,
                    ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: _searchController,
                      onChanged: notifier.setSearchQuery,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: l10n.searchByName,
                        hintStyle: AppTextStyles.bodySmall(context),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        prefixIcon: Icon(Icons.search_rounded, size: 18.r),
                        prefixIconConstraints: BoxConstraints(
                          minWidth: 36.w,
                          minHeight: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                          borderSide: const BorderSide(
                            color: AppColors.goldBorder,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    if (state.error != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Text(
                          state.error!,
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.danger),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: CommunityHeaderRow(
                                horizontalController:
                                    _headerHorizontalController,
                                fields: fields,
                                locale: locale,
                              ),
                            ),
                          ),
                          Expanded(
                            child: fieldsAsync.isLoading
                                ? const _SheetLoadingShimmer()
                                : state.isLoading
                                ? const _SheetLoadingShimmer()
                                : RefreshIndicator(
                                    color: AppColors.gold,
                                    backgroundColor: AppColors.emeraldMid,
                                    onRefresh: () async {
                                      await ref
                                          .read(communitySheetProvider.notifier)
                                          .refresh();
                                    },
                                    child: CustomScrollView(
                                      key: const PageStorageKey<String>(
                                        'community_sheet_scroll',
                                      ),
                                      controller: _verticalController,
                                      slivers: [
                                        if (ownRow != null ||
                                            ownPlaceholder != null)
                                          SliverToBoxAdapter(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                top: 8.h,
                                              ),
                                              child: Column(
                                                children: [
                                                  CommunityRowCard(
                                                    log:
                                                        ownRow ??
                                                        ownPlaceholder!,
                                                    fields: fields,
                                                    locale: locale,
                                                    horizontalController:
                                                        _controllerForRow(
                                                          'own-${currentUser?.uid ?? 'me'}',
                                                        ),
                                                    isToday: state.isToday,
                                                    isPinned: true,
                                                    isPending:
                                                        ownRow == null &&
                                                        state.isToday,
                                                    isPreAccount:
                                                        ownRow == null &&
                                                        isPreAccountDate,
                                                    onTap: ownRow == null
                                                        ? null
                                                        : () {
                                                            context.push(
                                                              '${AppRoutes.userProfile}/${ownRow!.uid}?date=${state.selectedDate}',
                                                              extra: ownRow,
                                                            );
                                                          },
                                                  ),
                                                  if (ownRow == null &&
                                                      isPreAccountDate)
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        top: 8.h,
                                                      ),
                                                      child: CardContainer(
                                                        color:
                                                            AppColors.cardDark,
                                                        borderColor: AppColors
                                                            .cardBorder,
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .info_outline_rounded,
                                                              color: AppColors
                                                                  .textMuted,
                                                              size: 16.r,
                                                            ),
                                                            SizedBox(
                                                              width: 10.w,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                'You had not created your account on this date.',
                                                                style:
                                                                    AppTextStyles.bodySmall(
                                                                      context,
                                                                    ).copyWith(
                                                                      color: AppColors
                                                                          .textMuted,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  if (ownRow == null &&
                                                      state.isToday &&
                                                      !isPreAccountDate)
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        top: 8.h,
                                                      ),
                                                      child: CardContainer(
                                                        color:
                                                            AppColors.goldCard,
                                                        borderColor: AppColors
                                                            .goldBorder,
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .schedule_outlined,
                                                              color: AppColors
                                                                  .gold,
                                                              size: 16.r,
                                                            ),
                                                            SizedBox(
                                                              width: 10.w,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                l10n.logTodayToAppear,
                                                                style:
                                                                    AppTextStyles.bodySmall(
                                                                      context,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (otherRows.isEmpty)
                                          SliverFillRemaining(
                                            hasScrollBody: false,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 16.h,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  l10n.noLogsForDay,
                                                  textAlign: TextAlign.center,
                                                  style:
                                                      AppTextStyles.bodyMedium(
                                                        context,
                                                      ).copyWith(
                                                        color:
                                                            AppColors.textMuted,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          SliverList(
                                            delegate: SliverChildBuilderDelegate((
                                              context,
                                              index,
                                            ) {
                                              final row = otherRows[index];
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                  top: 8.h,
                                                ),
                                                child: RepaintBoundary(
                                                  key: ValueKey(row.uid),
                                                  child: CommunityRowCard(
                                                    log: row,
                                                    fields: fields,
                                                    locale: locale,
                                                    horizontalController:
                                                        _controllerForRow(
                                                          'row-${row.uid}',
                                                        ),
                                                    isToday: state.isToday,
                                                    onTap: () {
                                                      context.push(
                                                        '${AppRoutes.userProfile}/${row.uid}?date=${state.selectedDate}',
                                                        extra: row,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              );
                                            }, childCount: otherRows.length),
                                          ),
                                        SliverToBoxAdapter(
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              top: 12.h,
                                              bottom: 20.h,
                                            ),
                                            child: Center(
                                              child: state.isLoadingMore
                                                  ? CircularProgressIndicator(
                                                      color: AppColors.gold,
                                                    )
                                                  : (!state.hasMore
                                                        ? Text(
                                                            l10n.noMoreRows,
                                                            style:
                                                                AppTextStyles.bodySmall(
                                                                  context,
                                                                ),
                                                          )
                                                        : const SizedBox.shrink()),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const _ActivityFeedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-Screen Community Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CommunitySheetFullScreen extends ConsumerStatefulWidget {
  const _CommunitySheetFullScreen();

  @override
  ConsumerState<_CommunitySheetFullScreen> createState() =>
      _CommunitySheetFullScreenState();
}

class _CommunitySheetFullScreenState
    extends ConsumerState<_CommunitySheetFullScreen> {
  late final ScrollController _headerHorizontalController;
  late final ScrollController _verticalController;
  late final TextEditingController _searchController;
  final Map<String, ScrollController> _rowHorizontalControllers = {};
  bool _isSyncingHorizontal = false;
  double _horizontalOffset = 0;
  bool _searchExpanded = false;
  bool _offlineSnackBarShown = false;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController = ScrollController();
    _headerHorizontalController.addListener(
      () => _syncHorizontalOffsets(_headerHorizontalController),
    );
    _verticalController = ScrollController()..addListener(_onVerticalScroll);
    _searchController = TextEditingController();

    // Sync initial search query from the shared provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final query = ref.read(communitySheetProvider).searchQuery;
      if (query.isNotEmpty) {
        _searchController.value = TextEditingValue(
          text: query,
          selection: TextSelection.collapsed(offset: query.length),
        );
        setState(() => _searchExpanded = true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _verticalController
      ..removeListener(_onVerticalScroll)
      ..dispose();
    _headerHorizontalController.dispose();
    for (final controller in _rowHorizontalControllers.values) {
      controller.dispose();
    }
    _rowHorizontalControllers.clear();
    super.dispose();
  }

  void _onVerticalScroll() {
    if (!_verticalController.hasClients) return;
    final max = _verticalController.position.maxScrollExtent;
    final cur = _verticalController.offset;
    if (max - cur < 180) {
      ref.read(communitySheetProvider.notifier).loadMore();
    }
  }

  ScrollController _controllerForRow(String key) {
    return _rowHorizontalControllers.putIfAbsent(key, () {
      final controller = ScrollController(
        initialScrollOffset: _horizontalOffset,
      );
      controller.addListener(() => _syncHorizontalOffsets(controller));
      return controller;
    });
  }

  void _syncHorizontalOffsets(ScrollController source) {
    if (_isSyncingHorizontal || source.positions.length != 1) return;
    _isSyncingHorizontal = true;
    try {
      _horizontalOffset = source.offset;
      final allControllers = <ScrollController>[
        _headerHorizontalController,
        ..._rowHorizontalControllers.values,
      ];
      for (final controller in allControllers) {
        if (identical(controller, source) || controller.positions.length != 1) {
          continue;
        }
        final max = controller.position.maxScrollExtent;
        final nextOffset = _horizontalOffset.clamp(0.0, max);
        if ((controller.offset - nextOffset).abs() > 0.5) {
          controller.jumpTo(nextOffset);
        }
      }
    } catch (e) {
      debugPrint('Sync offset error: $e');
    } finally {
      _isSyncingHorizontal = false;
    }
  }

  void _cleanupStaleRowControllers(Iterable<String> activeKeys) {
    final active = activeKeys.toSet();
    final stale = _rowHorizontalControllers.keys
        .where((k) => !active.contains(k))
        .toList();
    for (final key in stale) {
      _rowHorizontalControllers.remove(key)?.dispose();
    }
  }

  void _maybeShowOfflineSnackBar(BuildContext ctx, bool isOffline) {
    if (!isOffline || _offlineSnackBarShown) return;
    _offlineSnackBarShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(ctx)!;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 16),
              SizedBox(width: 8.w),
              Expanded(child: Text(l10n.offlineShowingLatest)),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.warning.withValues(alpha: 0.92),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md.r),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final fieldsAsync = ref.watch(amalFieldsProvider);
    final fields = ref.watch(amalFieldsListProvider);
    final state = ref.watch(communitySheetProvider);
    final notifier = ref.read(communitySheetProvider.notifier);
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final connectivity = ref.watch(connectivityListProvider);
    final dates = ref.watch(communityRecentDatesProvider);
    final accountCreatedHijri = ref.watch(communityAccountCreatedHijriProvider);
    final isPreAccountDate =
        accountCreatedHijri != null &&
        state.selectedDate.compareTo(accountCreatedHijri) < 0;

    // Transient offline notice — shown once via SnackBar
    final isOffline =
        connectivity.asData?.value.any((r) => r == ConnectivityResult.none) ??
        false;
    _maybeShowOfflineSnackBar(context, isOffline);

    final ownLogAsync = currentUser != null
        ? ref.watch(
            dayDetailLogProvider(
              DayLogKey(uid: currentUser.uid, hijriDate: state.selectedDate),
            ),
          )
        : null;
    final fetchedOwnRow = ownLogAsync?.value;

    var ownRow = state.ownRow(currentUser?.uid);
    if (ownRow == null && fetchedOwnRow != null) {
      ownRow = fetchedOwnRow;
    } else if (ownRow != null && fetchedOwnRow != null) {
      if (fetchedOwnRow.editCount > ownRow.editCount) {
        ownRow = fetchedOwnRow;
      }
    }

    final otherRows = state.filteredRowsExcludingUid(currentUser?.uid);
    final ownPlaceholder = currentUser == null
        ? null
        : _buildOwnPlaceholder(
            currentUser.uid,
            currentUser.name,
            state.selectedDate,
            fields,
          );

    // Keep search field in sync with provider (e.g. if cleared elsewhere)
    ref.listen(communitySheetProvider.select((s) => s.searchQuery), (_, query) {
      if (_searchController.text != query) {
        _searchController.value = TextEditingValue(
          text: query,
          selection: TextSelection.collapsed(offset: query.length),
        );
      }
    });

    final activeRowKeys = <String>[
      if (ownRow != null || ownPlaceholder != null)
        'fs-own-${currentUser?.uid ?? 'me'}',
      ...otherRows.map((row) => 'fs-row-${row.uid}'),
    ];
    _cleanupStaleRowControllers(activeRowKeys);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.emeraldDeep,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top actions: [search icon] [close X] ──
              Padding(
                padding: EdgeInsets.only(top: 8.h, right: 8.w, left: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Search toggle
                    IconButton(
                      icon: Icon(
                        _searchExpanded
                            ? Icons.search_off_rounded
                            : Icons.search_rounded,
                        color: _searchExpanded
                            ? AppColors.goldLight
                            : AppColors.textSecondary,
                        size: 22.r,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchExpanded = !_searchExpanded;
                          if (!_searchExpanded) {
                            notifier.setSearchQuery('');
                          }
                        });
                      },
                      tooltip: _searchExpanded ? 'Hide search' : 'Search',
                    ),
                    SizedBox(width: 4.w),
                    // Close full-screen
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 22.r,
                      ),
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      tooltip: 'Close full screen',
                    ),
                  ],
                ),
              ),

              // ── Animated Full-Width Search Field ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: child,
                  ),
                ),
                child: _searchExpanded
                    ? Padding(
                        key: const ValueKey('fs-search-field'),
                        padding: EdgeInsets.only(
                          left: 16.w,
                          right: 16.w,
                          bottom: 16.h,
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: notifier.setSearchQuery,
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: l10n.searchByName,
                            hintStyle: AppTextStyles.bodyMedium(
                              context,
                            ).copyWith(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.cardDark,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.md.r,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.cardBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.md.r,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.cardBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.md.r,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.goldBorder,
                              ),
                            ),
                            suffixIcon: state.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 18.r,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () {
                                      notifier.setSearchQuery('');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      )
                    : SizedBox.shrink(key: const ValueKey('fs-search-hidden')),
              ),

              if (!_searchExpanded) SizedBox(height: 8.h),

              // ── Date tabs (your only navigation) ───────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _DateTabsRow(
                  options: dates,
                  selectedDate: state.selectedDate,
                  onTapDate: notifier.selectDate,
                  locale: locale,
                ),
              ),
              SizedBox(height: 12.h),

              // ── Data grid ──────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: CommunityHeaderRow(
                            horizontalController: _headerHorizontalController,
                            fields: fields,
                            locale: locale,
                          ),
                        ),
                      ),
                      Expanded(
                        child: fieldsAsync.isLoading || state.isLoading
                            ? const _SheetLoadingShimmer()
                            : RefreshIndicator(
                                color: AppColors.gold,
                                backgroundColor: AppColors.emeraldMid,
                                onRefresh: () async {
                                  await ref
                                      .read(communitySheetProvider.notifier)
                                      .refresh();
                                },
                                child: CustomScrollView(
                                  key: const PageStorageKey<String>(
                                    'fs_community_sheet_scroll',
                                  ),
                                  controller: _verticalController,
                                  slivers: [
                                    if (ownRow != null ||
                                        ownPlaceholder != null)
                                      SliverToBoxAdapter(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 6.h),
                                          child: CommunityRowCard(
                                            log: ownRow ?? ownPlaceholder!,
                                            fields: fields,
                                            locale: locale,
                                            horizontalController: _controllerForRow(
                                              'fs-own-${currentUser?.uid ?? 'me'}',
                                            ),
                                            isToday: state.isToday,
                                            isPinned: true,
                                            isPending:
                                                ownRow == null && state.isToday,
                                            isPreAccount:
                                                ownRow == null &&
                                                isPreAccountDate,
                                            compact: true,
                                            onTap: ownRow == null
                                                ? null
                                                : () {
                                                    context.push(
                                                      '${AppRoutes.userProfile}/${ownRow!.uid}?date=${state.selectedDate}',
                                                      extra: ownRow,
                                                    );
                                                  },
                                          ),
                                        ),
                                      ),
                                    if (otherRows.isEmpty)
                                      SliverFillRemaining(
                                        hasScrollBody: false,
                                        child: Center(
                                          child: Text(
                                            l10n.noLogsForDay,
                                            textAlign: TextAlign.center,
                                            style:
                                                AppTextStyles.bodyMedium(
                                                  context,
                                                ).copyWith(
                                                  color: AppColors.textMuted,
                                                ),
                                          ),
                                        ),
                                      )
                                    else
                                      SliverList(
                                        delegate: SliverChildBuilderDelegate((
                                          context,
                                          index,
                                        ) {
                                          final row = otherRows[index];
                                          return Padding(
                                            padding: EdgeInsets.only(top: 6.h),
                                            child: RepaintBoundary(
                                              key: ValueKey('fs-${row.uid}'),
                                              child: CommunityRowCard(
                                                log: row,
                                                fields: fields,
                                                locale: locale,
                                                horizontalController:
                                                    _controllerForRow(
                                                      'fs-row-${row.uid}',
                                                    ),
                                                isToday: state.isToday,
                                                compact: true,
                                                onTap: () {
                                                  context.push(
                                                    '${AppRoutes.userProfile}/${row.uid}?date=${state.selectedDate}',
                                                    extra: row,
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        }, childCount: otherRows.length),
                                      ),
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          top: 12.h,
                                          bottom: 16.h,
                                        ),
                                        child: Center(
                                          child: state.isLoadingMore
                                              ? CircularProgressIndicator(
                                                  color: AppColors.gold,
                                                )
                                              : (!state.hasMore
                                                    ? Text(
                                                        l10n.noMoreRows,
                                                        style:
                                                            AppTextStyles.bodySmall(
                                                              context,
                                                            ),
                                                      )
                                                    : const SizedBox.shrink()),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
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

class _ActivityFeedTab extends ConsumerWidget {
  const _ActivityFeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(activityFeedProvider);
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.emeraldMid,
      onRefresh: () async {
        ref.invalidate(activityFeedProvider);
      },
      child: feed.when(
        loading: () => const _FeedLoadingState(),
        error: (_, _) => Center(
          child: Text(
            AppLocalizations.of(context)!.unableLoadActivityFeed,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textMuted),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              children: [
                SizedBox(height: 100.h),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Text(
                      AppLocalizations.of(context)!.noActivityYet,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            key: const PageStorageKey<String>('community_feed_scroll'),
            itemCount: items.length,
            separatorBuilder: (_, _) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final item = items[index];
              return _FeedItemCard(item: item);
            },
          );
        },
      ),
    );
  }
}

class _FeedItemCard extends StatelessWidget {
  const _FeedItemCard({required this.item});

  final ActivityFeedItemModel item;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForType(item.type);
    final onTap = item.type == 'dua'
        ? () => context.push(AppRoutes.notifications)
        : null;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30.w,
          height: 30.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.goldCard,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.goldBorder),
          ),
          child: Text(icon, style: TextStyle(fontSize: 14.sp)),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textPrimary),
              ),
              SizedBox(height: 6.h),
              Text(
                _timeAgo(context, item.createdAt),
                style: AppTextStyles.bodySmall(context),
              ),
            ],
          ),
        ),
      ],
    );
    if (item.type == 'dua') {
      return CardContainer.gold(
        onTap: onTap,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: row,
      );
    }
    return CardContainer(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: row,
    );
  }

  String _iconForType(String type) {
    switch (type) {
      case 'completion':
        return '🌟';
      case 'streak':
        return '🔥';
      case 'community_count':
        return '👥';
      case 'quote':
        return '📜';
      case 'dua':
        return '🤲';
      default:
        return '•';
    }
  }
}

class _DateTabsRow extends StatelessWidget {
  const _DateTabsRow({
    required this.options,
    required this.selectedDate,
    required this.onTapDate,
    required this.locale,
  });

  final List<String> options;
  final String selectedDate;
  final ValueChanged<String> onTapDate;
  final String locale;

  @override
  Widget build(BuildContext context) {
    // Use the same source-of-truth as options — Bangladesh calendar.
    // Grab the first entry of a 1-item list; that is always "today" by the
    // same Hijri logic used to build the full 7-day options list.
    final today = IslamicDateService.recentHijriStoragesFromBangladeshCalendar(
      count: 1,
    ).first;

    final isSelectedToday = selectedDate == today;

    // When the user is on today, show all options (today tab is just the
    // first chip in the row, labelled "Today").
    // When the user is on a past date that IS in options, remove today from
    // the scrollable row (we show a dedicated "Today" button instead).
    // When the user is on a date NOT in options at all, keep the full list
    // visible so they can navigate back.
    final visibleOptions = isSelectedToday
        ? options
        : options.where((d) => d != today).toList();

    return Row(
      children: [
        // Dedicated "Today" pill — shown only when not currently on today.
        if (!isSelectedToday) ...[
          GestureDetector(
            onTap: () => onTapDate(today),
            child: Container(
              height: 34.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppColors.emeraldMid.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppRadius.md.r),
                border: Border.all(color: AppColors.emeraldLight),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.today,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
        Expanded(
          child: SizedBox(
            height: 34.h,
            child: visibleOptions.isEmpty
                ? const SizedBox.shrink()
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: visibleOptions.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      final date = visibleOptions[index];
                      final isToday = date == today;
                      final selected = date == selectedDate;

                      // First chip when viewing today gets the "Today" label.
                      final label = (isToday && isSelectedToday)
                          ? AppLocalizations.of(context)!.today
                          : _shortHijriLabel(date, locale);

                      return GestureDetector(
                        onTap: () => onTapDate(date),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.goldCard
                                : AppColors.cardDark,
                            borderRadius: BorderRadius.circular(AppRadius.md.r),
                            border: Border.all(
                              color: selected
                                  ? AppColors.goldBorder
                                  : AppColors.cardBorder,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: selected
                                    ? AppColors.goldLight
                                    : AppColors.textSecondary,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String _shortHijriLabel(String storage, String locale) {
    final display = HijriHelper.displayFromStorage(
      storage,
      languageCode: locale,
    );
    final parts = display.split(' ');
    if (parts.length < 2) return display;
    return '${parts[0]} ${parts[1]}';
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}

class _FeedLoadingState extends StatelessWidget {
  const _FeedLoadingState();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
      child: ListView.separated(
        itemCount: 5,
        separatorBuilder: (_, _) => SizedBox(height: 8.h),
        itemBuilder: (_, index) => Container(
          height: 74.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md.r),
          ),
        ),
      ),
    );
  }
}

class _SheetLoadingShimmer extends StatelessWidget {
  const _SheetLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
      child: ListView.separated(
        itemCount: 6,
        separatorBuilder: (_, _) => SizedBox(height: 8.h),
        itemBuilder: (_, index) => Container(
          height: 46.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md.r),
          ),
        ),
      ),
    );
  }
}

AmalLogModel _buildOwnPlaceholder(
  String uid,
  String name,
  String selectedDate,
  List<AmalField> fields,
) {
  return AmalLogModel(
    uid: uid,
    displayName: name,
    photoUrl: '',
    isAnonymousDisplay: false,
    hijriDate: selectedDate,
    toggles: <String, dynamic>{
      for (final f in fields) f.id: f.type == AmalType.numeric ? 0 : false,
    },
    score: 0,
    submittedAt: DateTime.now().toUtc(),
  );
}

String _timeAgo(BuildContext context, DateTime timestamp) {
  final l10n = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final diff = now.difference(timestamp.toLocal());
  if (diff.inMinutes < 1) return l10n.justNow;
  if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
  final weeks = (diff.inDays / 7).floor();
  return l10n.weeksAgo(weeks);
}
