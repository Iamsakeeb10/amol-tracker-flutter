import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/asma_ul_husna.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/husna_name_model.dart';
import '../../../../providers/asma_ul_husna_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(asmaUlHusnaProvider.notifier).refreshFromStorage();
    });
  }

  void _openDetail(HusnaName name) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AsmaUlHusnaDetailScreen(name: name),
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

    return AppScaffold(
      handleExitBack: false,
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
                    padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
                    child: HusnaProgressHeader(
                      learnedCount: state.learnedCount,
                      canStartQuiz: state.canStartQuiz,
                      onStartQuiz: _openQuiz,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10.h,
                      crossAxisSpacing: 10.w,
                      childAspectRatio: 0.92,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final name = kAsmaUlHusna[index];
                        return HusnaNameCard(
                          name: name,
                          isLearned: state.isLearned(name.number),
                          onTap: () => _openDetail(name),
                        );
                      },
                      childCount: kAsmaUlHusna.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
