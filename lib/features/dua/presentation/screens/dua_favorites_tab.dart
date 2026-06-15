import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/dua_provider.dart';
import '../widgets/dua_sub_category_row.dart';
import 'dua_reader_screen.dart';

class DuaFavoritesTab extends ConsumerStatefulWidget {
  const DuaFavoritesTab({super.key});

  @override
  ConsumerState<DuaFavoritesTab> createState() => _DuaFavoritesTabState();
}

class _DuaFavoritesTabState extends ConsumerState<DuaFavoritesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _openReader(List<int> duaIds, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DuaReaderScreen(
          duaIds: duaIds,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final favoritesAsync = ref.watch(favoriteDuasProvider);

    return favoritesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (_, _) => Center(
        child: Text(
          l10n.duaNoResults,
          style: AppTextStyles.bodyMedium(context),
        ),
      ),
      data: (duas) {
        if (duas.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline_rounded,
                    size: 48.r,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    l10n.duaNoFavorites,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final ids = duas.map((d) => d.duaId).toList(growable: false);

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 100.h),
          itemCount: duas.length,
          itemExtent: 72.h,
          itemBuilder: (context, index) {
            final dua = duas[index];
            return DuaListRow(
              index: index + 1,
              title: dua.title,
              onTap: () => _openReader(ids, index),
              trailing: Icon(
                Icons.star_rounded,
                color: AppColors.gold,
                size: 18.r,
              ),
            );
          },
        );
      },
    );
  }
}
