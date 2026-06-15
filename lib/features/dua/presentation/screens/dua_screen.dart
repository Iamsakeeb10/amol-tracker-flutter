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
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        title: Text(
          l10n.duaTitle,
          style: AppTextStyles.headlineMedium(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          indicatorWeight: 2.5,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTextStyles.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
          ),
          unselectedLabelStyle: AppTextStyles.bodyMedium(context).copyWith(
            fontSize: 13.sp,
          ),
          tabs: [
            Tab(text: l10n.duaFavoritesTab),
            Tab(text: l10n.duaCategoriesTab),
            Tab(text: l10n.duaAllTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DuaFavoritesTab(),
          DuaCategoriesTab(),
          DuaAllTab(),
        ],
      ),
    );
  }
}
