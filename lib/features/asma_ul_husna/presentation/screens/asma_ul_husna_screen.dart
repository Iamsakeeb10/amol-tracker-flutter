import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/asma_ul_husna_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../widgets/husna_filter_chips.dart';
import '../widgets/husna_name_card.dart';
import '../widgets/husna_progress_header.dart';
import 'asma_ul_husna_detail_screen.dart';
import 'asma_ul_husna_quiz_screen.dart';

class AsmaUlHusnaScreen extends ConsumerStatefulWidget {
  const AsmaUlHusnaScreen({super.key});

  @override
  ConsumerState<AsmaUlHusnaScreen> createState() => _AsmaUlHusnaScreenState();
}

class _AsmaUlHusnaScreenState extends ConsumerState<AsmaUlHusnaScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(asmaUlHusnaProvider.notifier).refreshFromStorage();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(int initialNumber) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AsmaUlHusnaDetailScreen(initialNumber: initialNumber),
      ),
    );
  }

  void _openQuiz() {
    final started = ref.read(asmaUlHusnaProvider.notifier).startQuiz();
    if (!started) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AsmaUlHusnaQuizScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(asmaUlHusnaProvider);
    final notifier = ref.read(asmaUlHusnaProvider.notifier);
    final names = state.filteredNames;

    return AppScaffold(
      handleExitBack: false,
      padding: EdgeInsets.zero,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.more),
        ),
        title: Text(
          l10n.asmaUlHusna,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.h, bottom: 12.h),
                    child: HusnaProgressHeader(
                      learnedCount: state.learnedCount,
                      learnedPercent: state.learnedPercent,
                      canStartQuiz: state.canStartQuiz,
                      onStartQuiz: _openQuiz,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TextField(
                      controller: _searchController,
                      onChanged: notifier.setSearchQuery,
                      style: AppTextStyles.bodyLarge(context),
                      decoration: InputDecoration(
                        hintText: l10n.husnaSearch,
                        hintStyle: AppTextStyles.bodyMedium(context),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        prefixIcon: Icon(Icons.search_rounded, size: 20.r),
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
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                    child: HusnaFilterChips(
                      selected: state.filterMode,
                      onChanged: notifier.setFilterMode,
                    ),
                  ),
                ),
                if (names.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        l10n.husnaSearch,
                        style: AppTextStyles.bodyMedium(context),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final name = names[index];
                          return HusnaNameCard(
                            name: name,
                            isLearned: state.isLearned(name.number),
                            onTap: () => _openDetail(name.number),
                          );
                        },
                        childCount: names.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
