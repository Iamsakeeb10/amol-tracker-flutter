import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/dua_provider.dart';
import '../widgets/dua_sub_category_row.dart';
import '../widgets/dua_tab_scroll.dart';
import 'dua_reader_screen.dart';

class DuaAllTab extends ConsumerWidget {
  const DuaAllTab({super.key, required this.query});

  final String query;

  void _openReader(BuildContext context, List<int> duaIds, int initialIndex) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final duasAsync = ref.watch(duasListProvider);

    return duasAsync.when(
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
        final lowerQuery = query.toLowerCase();
        final filtered = query.isEmpty
            ? allDuas
            : allDuas
                .where(
                  (d) =>
                      d.title.toLowerCase().contains(lowerQuery) ||
                      d.translation.toLowerCase().contains(lowerQuery) ||
                      d.arabic.contains(query),
                )
                .toList(growable: false);

        final ids = filtered.map((d) => d.duaId).toList(growable: false);

        if (filtered.isEmpty) {
          return DuaTabScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    l10n.duaNoResults,
                    style: AppTextStyles.bodyMedium(context),
                  ),
                ),
              ),
            ],
          );
        }

        return DuaTabScrollView(
          slivers: [
            SliverList.builder(
              addAutomaticKeepAlives: false,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final dua = filtered[index];
                return DuaListRow(
                  index: dua.duaId,
                  title: dua.title,
                  onTap: () => _openReader(context, ids, index),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
