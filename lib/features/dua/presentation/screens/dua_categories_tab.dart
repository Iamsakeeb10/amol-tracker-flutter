import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../models/dua_models.dart';
import '../../providers/dua_provider.dart';
import '../widgets/dua_category_card.dart';
import 'dua_sub_categories_screen.dart';

class DuaCategoriesTab extends ConsumerStatefulWidget {
  const DuaCategoriesTab({super.key});

  @override
  ConsumerState<DuaCategoriesTab> createState() => _DuaCategoriesTabState();
}

class _DuaCategoriesTabState extends ConsumerState<DuaCategoriesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _openCategory(DuaCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DuaSubCategoriesScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final categoriesAsync = ref.watch(duaCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (_, _) => Center(
        child: Text(
          'Failed to load categories',
          style: AppTextStyles.bodyMedium(context),
        ),
      ),
      data: (categories) => GridView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 100.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 0.72,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return DuaCategoryCard(
            category: category,
            onTap: () => _openCategory(category),
          );
        },
      ),
    );
  }
}
