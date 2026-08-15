import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../providers/battle_providers.dart';

class BattleResultsScreen extends ConsumerStatefulWidget {
  final String battleCode;

  const BattleResultsScreen({super.key, required this.battleCode});

  @override
  ConsumerState<BattleResultsScreen> createState() => _BattleResultsScreenState();
}

class _BattleResultsScreenState extends ConsumerState<BattleResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocalStorageService.clearActiveBattleCode();
    });
  }

  void _goToHome() {
    if (!mounted) return;
    
    // Try to pop until battleHome. If battleHome is not in stack, this might pop to first route.
    bool foundBattleHome = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == 'battleHome') {
        foundBattleHome = true;
        return true;
      }
      if (route.isFirst) return true;
      return false;
    });

    // If we reached the first route and it wasn't battleHome, push battleHome
    if (!foundBattleHome && mounted) {
      context.pushReplacement(AppRoutes.battleHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).languageCode;
    final isBn = locale == 'bn';
    final resultAsync = ref.watch(battleResultProvider(widget.battleCode));
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final currentUid = currentUser?.uid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _goToHome();
      },
      child: AppScaffold(
        handleExitBack: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            isBn ? 'ফলাফল' : 'Results',
            style: AppTextStyles.headlineMedium(context),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: _goToHome,
          ),
        ),
        body: resultAsync.when(
          data: (result) {
            if (result == null) {
              return Center(
                child: Text(
                  isBn ? 'ফলাফল তৈরি হচ্ছে...' : 'Generating results...',
                  style: AppTextStyles.titleMedium(context),
                ),
              );
            }

            // Determine outcome
            String headerText = '';
            Color headerColor = AppColors.gold;

            if (result.winnerUid == null) {
              headerText = isBn ? 'ড্র!' : 'Draw!';
              headerColor = AppColors.ice;
            } else if (result.winnerUid == currentUid) {
              headerText = isBn ? 'বিজয়ী!' : 'Victory!';
              headerColor = AppColors.success;
            } else {
              headerText = isBn ? 'পরাজিত' : 'Defeat';
              headerColor = AppColors.danger;
            }

            final myResult = result.players.firstWhere(
              (p) => p.uid == currentUid,
              orElse: () => result.players.first,
            );
            final questions = result.questions;

            return ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              children: [
                // Header
                Center(
                  child: Text(
                    headerText,
                    style: AppTextStyles.displayMedium(context).copyWith(
                      color: headerColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: Text(
                    '+${myResult.score} XP',
                    style: AppTextStyles.titleLarge(context).copyWith(color: AppColors.gold),
                  ),
                ),
                SizedBox(height: 32.h),

                // Scoreboard
                Text(
                  isBn ? 'লিডারবোর্ড' : 'Leaderboard',
                  style: AppTextStyles.titleLarge(context),
                ),
                SizedBox(height: 16.h),
                CardContainer(
                  padding: EdgeInsets.zero,
                  color: AppColors.emeraldMid,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: result.players.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.emeraldLight, height: 1),
                    itemBuilder: (context, index) {
                      final p = result.players[index];
                      final isMe = p.uid == currentUid;
                      return ListTile(
                        leading: AvatarChip(
                          initial: isMe ? 'You' : 'P${index + 1}',
                          color: isMe ? AppColors.gold : AppColors.ice,
                        ),
                        title: Text(
                          isMe ? (isBn ? 'আপনি' : 'You') : 'Player ${index + 1}',
                          style: AppTextStyles.titleMedium(context).copyWith(
                            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                            color: isMe ? AppColors.gold : AppColors.textPrimary,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${p.score} pts',
                              style: AppTextStyles.titleSmall(context).copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(p.totalTimeMs / 1000).toStringAsFixed(1)}s',
                              style: AppTextStyles.labelSmall(context).copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 32.h),

                // Review
                if (questions.isNotEmpty) ...[
                  Text(
                    isBn ? 'প্রশ্নের পর্যালোচনা' : 'Question Review',
                    style: AppTextStyles.titleLarge(context),
                  ),
                  SizedBox(height: 16.h),
                  ...questions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final q = entry.value;
                    final text = q['text'];
                    final explanation = q['explanation'];
                    final correctIndex = q['correctIndex'] as int?;
                    final options = List<String>.from(q['options']);

                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: CardContainer(
                        padding: EdgeInsets.all(16.r),
                        color: AppColors.emeraldMid,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${isBn ? 'প্রশ্ন' : 'Q'}${i + 1}: $text',
                              style: AppTextStyles.titleMedium(context).copyWith(height: 1.4),
                            ),
                            SizedBox(height: 12.h),
                            if (correctIndex != null && correctIndex < options.length)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle, color: AppColors.success, size: 20.r),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      options[correctIndex],
                                      style: AppTextStyles.bodyMedium(context).copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (explanation != null && explanation.toString().isNotEmpty) ...[
                              SizedBox(height: 12.h),
                              Text(
                                explanation,
                                style: AppTextStyles.bodySmall(context).copyWith(
                                  color: AppColors.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: _goToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text(
                    isBn ? 'আবার খেলুন' : 'Play Again',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 32.h),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
