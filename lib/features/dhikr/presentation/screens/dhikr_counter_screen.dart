import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/dhikr_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../widgets/dhikr_bead_button.dart';
import '../widgets/dhikr_progress_arc.dart';
import '../widgets/dhikr_selector_sheet.dart';
import '../widgets/dhikr_session_list.dart';

class DhikrCounterScreen extends ConsumerStatefulWidget {
  const DhikrCounterScreen({super.key});

  @override
  ConsumerState<DhikrCounterScreen> createState() => _DhikrCounterScreenState();
}

class _DhikrCounterScreenState extends ConsumerState<DhikrCounterScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenViewed('dhikr');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dhikrProvider.notifier).refreshFromStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(dhikrProvider);
    final notifier = ref.read(dhikrProvider.notifier);
    final preset = state.selectedPreset;

    return AppScaffold(
      handleExitBack: false,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.more),
        ),
        title: Text(
          l10n.dhikrCounter,
          style: AppTextStyles.headlineMedium(context),
        ),
        actions: [
          IconButton(
            tooltip: l10n.dhikrReset,
            onPressed: state.count == 0 ? null : notifier.reset,
            icon: Icon(Icons.restart_alt_rounded, size: 22.r),
          ),
        ],
      ),
      body: state.isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: EdgeInsets.fromLTRB(0, 8.h, 0, 24.h),
              children: [
                CardContainer(
                  onTap: () => showDhikrSelectorSheet(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.displayName(l10n),
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.sp,
                              ),
                            ),
                            if (preset.arabicName != null) ...[
                              SizedBox(height: 2.h),
                              Text(
                                preset.arabicName!,
                                style: AppTextStyles.bodySmall(context).copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.expand_more, color: AppColors.gold, size: 24.r),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                Center(
                  child: DhikrProgressArc(
                    count: state.count,
                    target: preset.target,
                    justCompleted: state.justCompleted,
                    countLabel: l10n.dhikrCount,
                    targetLabel: l10n.dhikrTarget(preset.target),
                  ),
                ),
                if (state.justCompleted) ...[
                  SizedBox(height: 12.h),
                  Center(
                    child: Text(
                      l10n.dhikrCompleted,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 24.h),
                Center(
                  child: DhikrBeadButton(
                    onTap: notifier.tap,
                    enabled: !state.justCompleted,
                    justCompleted: state.justCompleted,
                  ),
                ),
                SizedBox(height: 12.h),
                Center(
                  child: DhikrTapHint(label: l10n.dhikrTapToCount),
                ),
                SizedBox(height: 28.h),
                DhikrSessionList(sessions: state.todaySessions),
              ],
            ),
    );
  }
}
