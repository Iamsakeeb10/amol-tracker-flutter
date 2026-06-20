import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/quran_surah.dart';
import '../../providers/quran_mushaf_provider.dart';
import '../../providers/quran_surah_provider.dart';

Future<void> showMushafJumpSheet(
  BuildContext context, {
  required int currentPage,
  required int totalPages,
  required ValueChanged<int> onJumpToPage,
  int initialTab = 0,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MushafJumpSheet(
      currentPage: currentPage,
      totalPages: totalPages,
      onJumpToPage: onJumpToPage,
      initialTab: initialTab,
    ),
  );
}

class MushafJumpSheet extends ConsumerStatefulWidget {
  const MushafJumpSheet({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onJumpToPage,
    this.initialTab = 0,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onJumpToPage;
  final int initialTab;

  @override
  ConsumerState<MushafJumpSheet> createState() => _MushafJumpSheetState();
}

class _MushafJumpSheetState extends ConsumerState<MushafJumpSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _pageController = TextEditingController();
  final _surahSearchController = TextEditingController();
  String _surahQuery = '';
  String? _pageError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _pageController.text = '${widget.currentPage}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _surahSearchController.dispose();
    super.dispose();
  }

  void _submitPage() {
    final parsed = int.tryParse(_pageController.text.trim());
    if (parsed == null) {
      setState(() => _pageError = 'Invalid page number');
      return;
    }
    if (parsed < 1 || parsed > widget.totalPages) {
      setState(
        () => _pageError = 'Enter a page between 1 and ${widget.totalPages}',
      );
      return;
    }
    Navigator.of(context).pop();
    widget.onJumpToPage(parsed);
  }

  List<QuranSurah> _filterSurahs(List<QuranSurah> surahs) {
    final q = _surahQuery.trim().toLowerCase();
    if (q.isEmpty) return surahs;
    return surahs
        .where(
          (s) =>
              s.nameAr.contains(_surahQuery.trim()) ||
              s.nameEn.toLowerCase().contains(q) ||
              s.nameBn.toLowerCase().contains(q) ||
              s.nameTransliteration.toLowerCase().contains(q) ||
              '${s.id}'.contains(q),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final surahsAsync = ref.watch(quranSurahListProvider);
    final startPagesAsync = ref.watch(mushafSurahStartPagesProvider);

    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 16.h),
      height: MediaQuery.sizeOf(context).height * 0.72,
      decoration: BoxDecoration(
        color: AppColors.emeraldMid,
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          SizedBox(height: 10.h),
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(99.r),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.gold,
            tabs: [
              Tab(text: l10n.quranJumpToPage),
              Tab(text: l10n.quranJumpToSurah),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.quranPageOf(
                          widget.currentPage,
                          widget.totalPages,
                        ),
                        style: AppTextStyles.bodyMedium(context),
                      ),
                      SizedBox(height: 16.h),
                      TextField(
                        controller: _pageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: l10n.quranJumpToPage,
                          hintText: '1 – ${widget.totalPages}',
                          errorText: _pageError,
                          filled: true,
                          fillColor: AppColors.emeraldDeep.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md.r),
                            borderSide: BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        onSubmitted: (_) => _submitPage(),
                      ),
                      SizedBox(height: 16.h),
                      FilledButton(
                        onPressed: _submitPage,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.emeraldDeep,
                        ),
                        child: Text(l10n.quranJumpToPage),
                      ),
                    ],
                  ),
                ),
                surahsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text(error.toString())),
                  data: (surahs) {
                    final startPages = startPagesAsync.asData?.value ?? {};
                    final filtered = _filterSurahs(surahs);
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                          child: TextField(
                            controller: _surahSearchController,
                            onChanged: (value) =>
                                setState(() => _surahQuery = value),
                            decoration: InputDecoration(
                              hintText: l10n.quranSearchHint,
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor:
                                  AppColors.emeraldDeep.withValues(alpha: 0.5),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md.r),
                                borderSide:
                                    BorderSide(color: AppColors.cardBorder),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => SizedBox(height: 4.h),
                            itemBuilder: (context, index) {
                              final surah = filtered[index];
                              final startPage =
                                  startPages[surah.id] ?? surah.startPage;
                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md.r),
                                ),
                                tileColor: AppColors.emeraldDeep
                                    .withValues(alpha: 0.35),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.gold.withValues(alpha: 0.15),
                                  child: Text(
                                    '${surah.id}',
                                    style: AppTextStyles.label(context).copyWith(
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  surah.displayName(languageCode),
                                  style: AppTextStyles.bodyLarge(context),
                                ),
                                subtitle: Text(
                                  '${l10n.quranPage(startPage)} • ${l10n.quranAyahs(surah.ayahCount)}',
                                  style: AppTextStyles.bodySmall(context),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  widget.onJumpToPage(startPage);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
