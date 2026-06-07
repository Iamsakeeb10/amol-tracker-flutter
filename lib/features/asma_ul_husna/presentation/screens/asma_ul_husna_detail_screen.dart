import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/asma_ul_husna.dart';
import '../../../../core/theme/colors.dart';
import '../../../../models/husna_name_model.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/asma_ul_husna_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';

class AsmaUlHusnaDetailScreen extends ConsumerStatefulWidget {
  const AsmaUlHusnaDetailScreen({super.key, required this.initialNumber});

  final int initialNumber;

  @override
  ConsumerState<AsmaUlHusnaDetailScreen> createState() =>
      _AsmaUlHusnaDetailScreenState();
}

class _AsmaUlHusnaDetailScreenState
    extends ConsumerState<AsmaUlHusnaDetailScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = (widget.initialNumber - 1).clamp(0, kHusnaTotalCount - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(asmaUlHusnaProvider);
    final name = kAsmaUlHusna[_currentIndex];
    final isLearned = state.isLearned(name.number);

    return AppScaffold(
      handleExitBack: false,
      appBar: AppBar(
        title: Text(
          l10n.husnaNumber(name.number),
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: kHusnaTotalCount,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final pageName = kAsmaUlHusna[index];
                return _DetailPage(name: pageName);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: Text(
              l10n.husnaSwipeHint,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textMuted,
                fontSize: 11.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    ref.read(asmaUlHusnaProvider.notifier).toggleLearned(name.number),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isLearned ? AppColors.cardBorder : AppColors.gold,
                  foregroundColor:
                      isLearned ? AppColors.textPrimary : AppColors.emeraldDeep,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: Icon(
                  isLearned
                      ? Icons.bookmark_remove_outlined
                      : Icons.bookmark_add_outlined,
                  size: 20.r,
                ),
                label: Text(
                  isLearned ? l10n.husnaMarkNotLearned : l10n.husnaMarkLearned,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color:
                        isLearned ? AppColors.textPrimary : AppColors.emeraldDeep,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPage extends StatelessWidget {
  const _DetailPage({required this.name});

  final HusnaName name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final meaning =
        name.localizedMeaningFromLocale(Localizations.localeOf(context));

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      children: [
        CardContainer(
          child: Column(
            children: [
              Text(
                name.arabic,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.displayLarge(context).copyWith(
                  fontSize: 36.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                width: 48.w,
                height: 2.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.goldLight],
                  ),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                l10n.husnaPronunciation,
                style: AppTextStyles.label(context),
              ),
              SizedBox(height: 4.h),
              Text(
                name.pronunciationBn,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                name.transliteration,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.husnaMeaning, style: AppTextStyles.label(context)),
              SizedBox(height: 6.h),
              Text(
                meaning,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        CardContainer(
          border: const Border(
            left: BorderSide(color: AppColors.gold, width: 3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.husnaBenefit, style: AppTextStyles.label(context)),
              SizedBox(height: 6.h),
              Text(
                name.benefit,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
