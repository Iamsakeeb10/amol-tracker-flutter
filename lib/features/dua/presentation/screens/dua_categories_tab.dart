import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../models/dua_models.dart';
import '../../providers/dua_provider.dart';
import '../widgets/dua_category_card.dart';
import '../widgets/dua_tab_scroll.dart';
import 'dua_sub_categories_screen.dart';

class DuaCategoriesTab extends ConsumerStatefulWidget {
  const DuaCategoriesTab({super.key});

  @override
  ConsumerState<DuaCategoriesTab> createState() => _DuaCategoriesTabState();
}

class _DuaCategoriesTabState extends ConsumerState<DuaCategoriesTab>
    with AutomaticKeepAliveClientMixin {
  static const _importanceOrder = <String, int>{
    'morning-and-evening': 0,
    'salah': 1,
    'ablution-and-bath': 2,
    'adhaan-and-iqamah': 3,
    'mosque': 4,
    'witr-and-other': 5,
    'sleep': 6,
    'food': 7,
    'home': 8,
    'cloths': 9,
    'toilet': 10,
    'evil-protection': 11,
    'forgiveness': 12,
    'manners': 13,
    'gathering': 14,
    'when-to-say-what': 15,
    'fasting': 16,
    'eid': 17,
    'sacrifice': 18,
    'hajj-and-umrah': 19,
    'travel': 20,
    'anxiety': 21,
    'danger': 22,
    'sickness': 23,
    'jinndiseases': 24,
    'marriage': 25,
    'family': 26,
    'debt': 27,
    'grave-funeral': 28,
    'animals': 29,
    'rainnature': 30,
    'condemnationpraise': 31,
    'quranic-dua': 32,
    '40-rabbana-duas': 33,
    'prophets-dua': 34,
    'duas-of-hadith': 35,
    'duas-of-sahaba': 36,
    'masnun-duas': 37,
    'greatest-name-of-allah': 38,
    'other-duas': 39,
    'duas-importance': 40,
    'duas-excellence': 41,
    'time-of-dua': 42,
    'dua-acceptance': 43,
  };

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
      data: (categories) {
        final sorted = [...categories]
          ..sort((a, b) {
            final ia = _importanceOrder[a.url] ?? 999;
            final ib = _importanceOrder[b.url] ?? 999;
            return ia.compareTo(ib);
          });

        return DuaTabScrollView(
          slivers: [
            SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16.h,
                crossAxisSpacing: 12.w,
                childAspectRatio: 0.72,
              ),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final category = sorted[index];
                return DuaCategoryCard(
                  category: category,
                  onTap: () => _openCategory(category),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
