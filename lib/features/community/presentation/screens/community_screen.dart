import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/router/routes.dart';
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
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/community_row_card.dart';
import '../../../../shared/widgets/section_header.dart';

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
    final locale = Localizations.localeOf(context).languageCode;
    final fieldsAsync = ref.watch(amalFieldsProvider);
    final fields = ref.watch(amalFieldsListProvider);
    final state = ref.watch(communitySheetProvider);
    final notifier = ref.read(communitySheetProvider.notifier);
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final connectivity = ref.watch(connectivityListProvider);
    final dates = _buildDateOptions(count: 7);
    final accountCreatedHijri = currentUser == null
        ? null
        : () {
            final createdAtLocal = currentUser.createdAt.toLocal();
            final nowBd = IslamicDateService.nowInBD();
            final createdOnCurrentGregorianDay =
                createdAtLocal.year == nowBd.year &&
                createdAtLocal.month == nowBd.month &&
                createdAtLocal.day == nowBd.day;

            // New accounts created "today" should not be counted as misses for
            // earlier dates because the global Hijri -1 correction can map
            // today's Gregorian date to the previous Hijri day.
            if (createdOnCurrentGregorianDay) {
              return IslamicDateService.getCurrentIslamicDateStringSafe();
            }

            return IslamicDateService.islamicDateStringForGregorianDate(
              createdAtLocal,
            );
          }();
    final isPreAccountDate =
        accountCreatedHijri != null &&
        state.selectedDate.compareTo(accountCreatedHijri) < 0;

    final ownRow = state.ownRow(currentUser?.uid);
    final otherRows = state.filteredRowsExcludingUid(currentUser?.uid);
    final ownPlaceholder = currentUser == null
        ? null
        : _buildOwnPlaceholder(
            currentUser.uid,
            currentUser.name,
            state.selectedDate,
            fields,
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
                        child: fieldsAsync.isLoading
                            ? const _SheetLoadingShimmer()
                            : state.isLoading
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
                                      minHeight: kCommunityHeaderRowHeight.h,
                                      maxHeight: kCommunityHeaderRowHeight.h,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md.r,
                                        ),
                                        child: CommunityHeaderRow(
                                          horizontalController:
                                              _headerHorizontalController,
                                          fields: fields,
                                          locale: locale,
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
                                                        '${AppRoutes.userProfile}/${ownRow.uid}?date=${state.selectedDate}',
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
                                                  color: AppColors.cardDark,
                                                  borderColor:
                                                      AppColors.cardBorder,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .info_outline_rounded,
                                                        color:
                                                            AppColors.textMuted,
                                                        size: 16.r,
                                                      ),
                                                      SizedBox(width: 10.w),
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
  });

  final List<String> options;
  final String selectedDate;
  final ValueChanged<String> onTapDate;

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
                          : _shortHijriLabel(date);

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
  return IslamicDateService.recentHijriStoragesFromBangladeshCalendar(
    count: count,
  );
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
      for (final f in fields)
        f.id: f.type == AmalType.numeric ? 0 : false,
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
