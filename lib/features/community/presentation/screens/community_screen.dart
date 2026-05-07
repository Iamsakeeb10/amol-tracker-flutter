import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/hijri_helper.dart';
import '../../../../models/activity_feed_item_model.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../providers/amal_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/community_row_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  late final ScrollController _headerHorizontalController;
  late final ScrollController _verticalController;
  late final TextEditingController _searchController;
  final Map<String, ScrollController> _rowHorizontalControllers = {};
  bool _isSyncingHorizontal = false;
  double _horizontalOffset = 0;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController = ScrollController();
    _headerHorizontalController.addListener(
      () => _syncHorizontalOffsets(_headerHorizontalController),
    );
    _verticalController = ScrollController()..addListener(_onVerticalScroll);
    _searchController = TextEditingController();
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
    if (_isSyncingHorizontal || !source.hasClients) return;
    _isSyncingHorizontal = true;
    _horizontalOffset = source.offset;
    final allControllers = <ScrollController>[
      _headerHorizontalController,
      ..._rowHorizontalControllers.values,
    ];
    for (final controller in allControllers) {
      if (identical(controller, source) || !controller.hasClients) continue;
      final max = controller.position.maxScrollExtent;
      final nextOffset = _horizontalOffset.clamp(0.0, max);
      if ((controller.offset - nextOffset).abs() > 0.5) {
        controller.jumpTo(nextOffset);
      }
    }
    _isSyncingHorizontal = false;
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
    final state = ref.watch(communitySheetProvider);
    final notifier = ref.read(communitySheetProvider.notifier);
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final connectivity = ref.watch(connectivityListProvider);
    final dates = _buildDateOptions(count: 7);

    final ownRow = state.ownRow(currentUser?.uid);
    final otherRows = state.filteredRowsExcludingUid(currentUser?.uid);
    final ownPlaceholder = currentUser == null
        ? null
        : _buildOwnPlaceholder(
            currentUser.uid,
            currentUser.name,
            state.selectedDate,
          );

    if (_searchController.text != state.searchQuery) {
      _searchController.value = TextEditingValue(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    final activeRowKeys = <String>[
      if (ownRow != null || ownPlaceholder != null)
        'own-${currentUser?.uid ?? 'me'}',
      ...otherRows.map((row) => 'row-${row.uid}'),
    ];
    _cleanupStaleRowControllers(activeRowKeys);

    return AppScaffold(
      body: DefaultTabController(
        length: 2,
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
            Text(l10n.community, style: AppTextStyles.displayMedium(context)),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(3.r),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(AppRadius.md.r),
              ),
              child: TabBar(
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
                labelStyle: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTextStyles.bodyMedium(context),
                tabs: [
                  Tab(text: l10n.sheet),
                  Tab(text: l10n.feed),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: TabBarView(
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
                            color: AppColors.warningLight.withValues(
                              alpha: 0.35,
                            ),
                            borderColor: AppColors.warning.withValues(
                              alpha: 0.5,
                            ),
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
                        ),
                      ),
                      _DateTabsRow(
                        options: dates,
                        selectedDate: state.selectedDate,
                        onTapDate: notifier.selectDate,
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: _searchController,
                        onChanged: notifier.setSearchQuery,
                        decoration: InputDecoration(
                          hintText: l10n.searchByName,
                          hintStyle: AppTextStyles.bodyMedium(context),
                          filled: true,
                          fillColor: AppColors.cardDark,
                          prefixIcon: const Icon(Icons.search_rounded),
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
                        child: state.isLoading
                            ? const _SheetLoadingShimmer()
                            : CustomScrollView(
                                key: const PageStorageKey<String>(
                                  'community_sheet_scroll',
                                ),
                                controller: _verticalController,
                                slivers: [
                                  SliverPersistentHeader(
                                    pinned: true,
                                    delegate: _StickyHeaderDelegate(
                                      minHeight: 46.h,
                                      maxHeight: 46.h,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md.r,
                                        ),
                                        child: CommunityHeaderRow(
                                          horizontalController:
                                              _headerHorizontalController,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (ownRow != null || ownPlaceholder != null)
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 8.h),
                                        child: Column(
                                          children: [
                                            CommunityRowCard(
                                              log: ownRow ?? ownPlaceholder!,
                                              horizontalController:
                                                  _controllerForRow(
                                                    'own-${currentUser?.uid ?? 'me'}',
                                                  ),
                                              isToday: state.isToday,
                                              isPinned: true,
                                              isPending:
                                                  ownRow == null &&
                                                  state.isToday,
                                              onTap: ownRow == null
                                                  ? null
                                                  : () {
                                                      debugPrint(
                                                        '[CommunityTap][own] uid=${ownRow.uid} date=${state.selectedDate} score=${ownRow.score} toggles=${ownRow.toggles}',
                                                      );
                                                      context.push(
                                                        '${AppRoutes.userProfile}/${ownRow.uid}?date=${state.selectedDate}',
                                                        extra: ownRow,
                                                      );
                                                    },
                                            ),
                                            if (ownRow == null && state.isToday)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: 8.h,
                                                ),
                                                child: CardContainer(
                                                  color: AppColors.goldCard,
                                                  borderColor:
                                                      AppColors.goldBorder,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.schedule_outlined,
                                                        color: AppColors.gold,
                                                        size: 16.r,
                                                      ),
                                                      SizedBox(width: 10.w),
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
                                                  color: AppColors.textMuted,
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
                                          padding: EdgeInsets.only(top: 8.h),
                                          child: RepaintBoundary(
                                            key: ValueKey(row.uid),
                                            child: CommunityRowCard(
                                              log: row,
                                              horizontalController:
                                                  _controllerForRow(
                                                    'row-${row.uid}',
                                                  ),
                                              isToday: state.isToday,
                                              onTap: () {
                                                debugPrint(
                                                  '[CommunityTap][row] uid=${row.uid} date=${state.selectedDate} score=${row.score} toggles=${row.toggles}',
                                                );
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
                    ],
                  ),
                  const _ActivityFeedTab(),
                ],
              ),
            ),
          ],
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
    return feed.when(
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
          return Center(
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
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textPrimary),
              ),
              SizedBox(height: 6.h),
              Text(
                _timeAgo(item.createdAt),
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
  });

  final List<String> options;
  final String selectedDate;
  final ValueChanged<String> onTapDate;

  @override
  Widget build(BuildContext context) {
    final today = IslamicDateService.getCurrentIslamicDateString();
    return SizedBox(
      height: 34.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final date = options[index];
          final selected = date == selectedDate;
          final isToday = date == today;
          final label = isToday
              ? AppLocalizations.of(context)!.today
              : _shortHijriLabel(date);
          return GestureDetector(
            onTap: () => onTapDate(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: selected ? AppColors.goldCard : AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppRadius.md.r),
                border: Border.all(
                  color: selected ? AppColors.goldBorder : AppColors.cardBorder,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: selected
                        ? AppColors.goldLight
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _shortHijriLabel(String storage) {
    final display = HijriHelper.displayFromStorage(storage);
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

List<String> _buildDateOptions({required int count}) {
  final now = HijriHelper.bangladeshNow();
  return List<String>.generate(count, (index) {
    final day = now.subtract(Duration(days: index));
    final h = HijriCalendar.fromDate(day);
    return HijriHelper.storageFromParts(h.hYear, h.hMonth, h.hDay);
  });
}

AmalLogModel _buildOwnPlaceholder(
  String uid,
  String name,
  String selectedDate,
) {
  return AmalLogModel(
    uid: uid,
    displayName: name,
    photoUrl: '',
    isAnonymousDisplay: false,
    hijriDate: selectedDate,
    toggles: const <String, bool>{
      'fard': false,
      'takbir': false,
      'morning_azkar': false,
      'evening_azkar': false,
      'quran': false,
      'mulk': false,
      'miswak': false,
      'sunnah': false,
      'post_azkar': false,
    },
    score: 0,
    submittedAt: DateTime.now().toUtc(),
  );
}

String _timeAgo(DateTime timestamp) {
  final now = DateTime.now();
  final diff = now.difference(timestamp.toLocal());
  // time labels localized in notifications/feed style
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final weeks = (diff.inDays / 7).floor();
  return '${weeks}w ago';
}
