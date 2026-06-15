import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/dua_provider.dart';
import '../widgets/dua_sub_category_row.dart';
import 'dua_reader_screen.dart';

class DuaAllTab extends ConsumerStatefulWidget {
  const DuaAllTab({super.key});

  @override
  ConsumerState<DuaAllTab> createState() => _DuaAllTabState();
}

class _DuaAllTabState extends ConsumerState<DuaAllTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final duasAsync = ref.watch(duasListProvider);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value.trim()),
            style: AppTextStyles.bodyLarge(context),
            decoration: InputDecoration(
              hintText: l10n.duaSearchHint,
              hintStyle: AppTextStyles.bodyMedium(context),
              filled: true,
              fillColor: AppColors.cardDark,
              prefixIcon: Icon(Icons.search_rounded, size: 20.r),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, size: 20.r),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md.r),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md.r),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md.r),
                borderSide: const BorderSide(color: AppColors.goldBorder),
              ),
            ),
          ),
        ),
        Expanded(
          child: duasAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
            error: (_, _) => Center(
              child: Text(
                l10n.duaNoResults,
                style: AppTextStyles.bodyMedium(context),
              ),
            ),
            data: (allDuas) {
              final lowerQuery = _query.toLowerCase();
              final filtered = _query.isEmpty
                  ? allDuas
                  : allDuas
                      .where(
                        (d) =>
                            d.title.toLowerCase().contains(lowerQuery) ||
                            d.translation.toLowerCase().contains(lowerQuery) ||
                            d.arabic.contains(_query),
                      )
                      .toList(growable: false);

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    l10n.duaNoResults,
                    style: AppTextStyles.bodyMedium(context),
                  ),
                );
              }

              final ids = filtered.map((d) => d.duaId).toList(growable: false);

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                itemCount: filtered.length,
                itemExtent: 72.h,
                itemBuilder: (context, index) {
                  final dua = filtered[index];
                  return DuaListRow(
                    index: dua.duaId,
                    title: dua.title,
                    onTap: () => _openReader(ids, index),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
