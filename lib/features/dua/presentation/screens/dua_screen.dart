import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import 'dua_all_tab.dart';
import 'dua_categories_tab.dart';
import 'dua_favorites_tab.dart';

class DuaScreen extends ConsumerStatefulWidget {
  const DuaScreen({super.key});

  @override
  ConsumerState<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends ConsumerState<DuaScreen>
    with SingleTickerProviderStateMixin {
  static const _searchAnimDuration = Duration(milliseconds: 200);

  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  int _tabIndex = 1;
  bool _searchOpen = false;
  String _searchQuery = '';

  bool get _onAllDuasTab => _tabIndex == 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final nextIndex = _tabController.index;
    if (nextIndex != _tabIndex) {
      if (nextIndex != 2) _closeSearch(silent: true);
      setState(() => _tabIndex = nextIndex);
    }
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch({bool silent = false}) {
    _searchController.clear();
    _searchFocusNode.unfocus();
    if (!silent && mounted) {
      setState(() {
        _searchOpen = false;
        _searchQuery = '';
      });
    } else {
      _searchOpen = false;
      _searchQuery = '';
    }
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim();
    if (trimmed == _searchQuery) return;
    setState(() => _searchQuery = trimmed);
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
        centerTitle: !_searchOpen,
        automaticallyImplyLeading: false,
        toolbarHeight: 42.h,
        title: AnimatedSwitcher(
          duration: _searchAnimDuration,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: _searchOpen
              ? TextField(
                  key: const ValueKey('dua_search_field'),
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontSize: 15.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.duaSearchHint,
                    hintStyle: AppTextStyles.bodyMedium(context),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                )
              : Text(
                  l10n.duaTitle,
                  key: const ValueKey('dua_title'),
                  style: AppTextStyles.headlineMedium(context).copyWith(
                    fontSize: 17.5.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
        ),
        actions: _onAllDuasTab
            ? [
                IconButton(
                  tooltip: _searchOpen ? l10n.cancel : l10n.duaSearchHint,
                  icon: Icon(
                    _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                    size: 22.r,
                  ),
                  onPressed: _searchOpen ? _closeSearch : _openSearch,
                ),
              ]
            : null,
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
