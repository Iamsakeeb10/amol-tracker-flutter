import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../models/dua_models.dart';
import '../../providers/dua_provider.dart';
import '../widgets/dua_sub_category_row.dart';
import 'dua_reader_screen.dart';

class DuaSubCategoriesScreen extends ConsumerWidget {
  const DuaSubCategoriesScreen({super.key, required this.category});

  final DuaCategory category;

  void _openReader(BuildContext context, List<int> duaIds) {
    if (duaIds.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DuaReaderScreen(
          duaIds: duaIds,
          initialIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subCategoriesAsync =
        ref.watch(subCategoriesByCategoryProvider(category.url));

    return AppScaffold(
      handleExitBack: false,
      padding: EdgeInsets.zero,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          category.name,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: subCategoriesAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => Center(
          child: Text(
            'Failed to load sub-categories',
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
        data: (subCategories) => ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          itemCount: subCategories.length,
          itemBuilder: (context, index) {
            final sub = subCategories[index];
            return DuaSubCategoryRow(
              index: index + 1,
              title: sub.title,
              onTap: () => _openReader(context, sub.duaIds),
            );
          },
        ),
      ),
    );
  }
}
