import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/bottom_tab_back_button.dart';
import '../../models/dua_models.dart';
import '../../providers/dua_provider.dart';
import '../widgets/dua_reader_options_sheet.dart';
import 'dua_all_tab.dart';
import 'dua_categories_tab.dart';
import 'dua_favorites_tab.dart';
import 'dua_sub_categories_screen.dart';

class DuaScreen extends ConsumerStatefulWidget {
  const DuaScreen({super.key, this.initialCategoryUrl});

  final String? initialCategoryUrl;

  @override
  ConsumerState<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends ConsumerState<DuaScreen>
    with SingleTickerProviderStateMixin {
  static const _searchAnimDuration = Duration(milliseconds: 280);
  static const _searchAnimCurve = Curves.easeOutCubic;
  static const _searchAnimReverseCurve = Curves.easeInCubic;

  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  int _tabIndex = 1;
  bool _searchOpen = false;
  bool _pendingSearchOpen = false;
  bool _searchTransitioning = false;
  String _searchQuery = '';
  bool _initialCategoryHandled = false;

  bool get _onAllDuasTab => _tabIndex == 2;

  double get _actionIconSize => 24.r;

  ButtonStyle get _actionIconStyle => IconButton.styleFrom(
        padding: EdgeInsets.all(10.r),
        minimumSize: Size(44.r, 44.r),
        tapTargetSize: MaterialTapTargetSize.padded,
      );

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenViewed('dua');
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(duaCategoriesProvider.future);
      ref.read(duaSubCategoriesProvider.future);
      ref.read(duasMapProvider.future);
      _openInitialCategoryIfNeeded();
    });
  }

  Future<void> _openInitialCategoryIfNeeded() async {
    final categoryUrl = widget.initialCategoryUrl?.trim();
    if (categoryUrl == null || categoryUrl.isEmpty || _initialCategoryHandled) {
      return;
    }
    _initialCategoryHandled = true;

    try {
      final categories = await ref.read(duaCategoriesProvider.future);
      DuaCategory? category;
      for (final item in categories) {
        if (item.url == categoryUrl) {
          category = item;
          break;
        }
      }
      if (!mounted || category == null) return;

      final resolvedCategory = category;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DuaSubCategoriesScreen(category: resolvedCategory),
        ),
      );
    } catch (_) {
      // Keep the main dua screen visible if category navigation fails.
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final nextIndex = _tabController.index;
    if (nextIndex != _tabIndex) {
      if (nextIndex != 2) {
        _closeSearch(silent: true);
        _pendingSearchOpen = false;
      }
      setState(() => _tabIndex = nextIndex);
      if (nextIndex == 2 && _pendingSearchOpen) {
        _pendingSearchOpen = false;
        _openSearch();
      }
    }
  }

  void _openSearch() {
    if (_searchTransitioning) return;
    _searchTransitioning = true;
    setState(() => _searchOpen = true);
    Future<void>.delayed(_searchAnimDuration, () {
      if (!mounted) return;
      _searchTransitioning = false;
      if (_searchOpen) _searchFocusNode.requestFocus();
    });
  }

  void _openSearchFromAnyTab() {
    if (!_onAllDuasTab) {
      _pendingSearchOpen = true;
      _tabController.animateTo(2);
      return;
    }
    _openSearch();
  }

  void _onSearchAction() {
    if (_showSearchField) {
      _closeSearch();
    } else {
      _openSearchFromAnyTab();
    }
  }

  bool get _showSearchField => _searchOpen && _onAllDuasTab;

  Widget _buildAppBarTitle(AppLocalizations l10n) {
    final titleStyle = AppTextStyles.headlineMedium(
      context,
    ).copyWith(fontSize: 17.5.sp, fontWeight: FontWeight.w600, height: 0);
    const titleHeightBehavior = TextHeightBehavior(
      applyHeightToFirstAscent: false,
      applyHeightToLastDescent: false,
    );

    return SizedBox(
      height: 42.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedSize(
            duration: _searchAnimDuration,
            curve: _searchAnimCurve,
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.hardEdge,
            child: _showSearchField
                ? const SizedBox.shrink()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: _actionIconSize,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: 8.w),
                    ],
                  ),
          ),
          Expanded(
            child: SizedBox(
              height: 42.h,
              child: AnimatedSwitcher(
                duration: _searchAnimDuration,
                switchInCurve: _searchAnimCurve,
                switchOutCurve: _searchAnimReverseCurve,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.centerLeft,
                    fit: StackFit.expand,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final slideAnimation =
                      Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: _searchAnimCurve,
                          reverseCurve: _searchAnimReverseCurve,
                        ),
                      );
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slideAnimation,
                      child: child,
                    ),
                  );
                },
                child: _showSearchField
                    ? Align(
                        key: const ValueKey('dua_search_field'),
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                          style: AppTextStyles.bodyLarge(
                            context,
                          ).copyWith(fontSize: 15.sp, height: 1),
                          strutStyle: const StrutStyle(
                            height: 1,
                            forceStrutHeight: true,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.duaSearchHint,
                            hintStyle: AppTextStyles.bodyMedium(
                              context,
                            ).copyWith(height: 1),
                            border: InputBorder.none,
                            isDense: true,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10.h,
                            ),
                          ),
                        ),
                      )
                    : Align(
                        key: const ValueKey('dua_title'),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.duaTitle,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: titleStyle,
                          textHeightBehavior: titleHeightBehavior,
                          strutStyle: const StrutStyle(
                            height: 0,
                            forceStrutHeight: true,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(AppLocalizations l10n) {
    return [
      IconButton(
        tooltip: l10n.duaReaderOptions,
        style: _actionIconStyle,
        icon: Icon(Icons.tune_rounded, size: _actionIconSize),
        onPressed: () => showDuaReaderOptionsSheet(context),
      ),
      IconButton(
        tooltip: _showSearchField ? l10n.cancel : l10n.duaSearchHint,
        style: _actionIconStyle,
        onPressed: _onSearchAction,
        icon: AnimatedSwitcher(
          duration: _searchAnimDuration,
          switchInCurve: _searchAnimCurve,
          switchOutCurve: _searchAnimReverseCurve,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.82, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: _searchAnimCurve,
                    reverseCurve: _searchAnimReverseCurve,
                  ),
                ),
                child: child,
              ),
            );
          },
          child: Icon(
            _showSearchField ? Icons.close_rounded : Icons.search_rounded,
            key: ValueKey(_showSearchField),
            size: _actionIconSize,
          ),
        ),
      ),
    ];
  }

  void _closeSearch({bool silent = false}) {
    if (silent) {
      _searchController.clear();
      _searchFocusNode.unfocus();
      _searchOpen = false;
      _searchQuery = '';
      _searchTransitioning = false;
      return;
    }

    if (_searchTransitioning) return;
    _searchTransitioning = true;
    setState(() => _searchOpen = false);
    Future<void>.delayed(_searchAnimDuration, () {
      if (!mounted) return;
      _searchTransitioning = false;
      _searchController.clear();
      _searchFocusNode.unfocus();
      if (_searchQuery.isNotEmpty) {
        setState(() => _searchQuery = '');
      }
    });
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim();
    if (trimmed == _searchQuery) return;
    setState(() => _searchQuery = trimmed);
    if (trimmed.isNotEmpty) {
      AnalyticsService.instance.logSearchUsed(section: 'dua');
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        toolbarHeight: 52.h,
        leading: const BottomTabBackButton(),
        title: _buildAppBarTitle(l10n),
        actions: _buildActions(l10n),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(42.h),
          child: DecoratedBox(
            decoration: const BoxDecoration(boxShadow: []),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              dividerHeight: 0,
              indicatorColor: AppColors.gold,
              indicatorWeight: 2,
              labelPadding: EdgeInsets.symmetric(horizontal: 2.w),
              labelColor: AppColors.gold,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15.sp,
                height: 1.1,
              ),
              unselectedLabelStyle: AppTextStyles.bodyLarge(context).copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
              tabs: [
                Tab(text: l10n.duaFavoritesTab),
                Tab(text: l10n.duaCategoriesTab),
                Tab(text: l10n.duaAllTab),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const DuaFavoritesTab(),
          const DuaCategoriesTab(),
          DuaAllTab(query: _searchQuery),
        ],
      ),
    );
  }
}
