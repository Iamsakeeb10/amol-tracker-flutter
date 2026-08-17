import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/battle_providers.dart';

class BattleResultsScreen extends ConsumerStatefulWidget {
  final String battleCode;
  final bool fromHistory;

  const BattleResultsScreen({super.key, required this.battleCode, this.fromHistory = false});

  @override
  ConsumerState<BattleResultsScreen> createState() => _BattleResultsScreenState();
}

class _BattleResultsScreenState extends ConsumerState<BattleResultsScreen> with TickerProviderStateMixin {
  bool _isQuestionsExpanded = false;
  late final AnimationController _trophyController;

  @override
  void initState() {
    super.initState();
    _trophyController = AnimationController(vsync: this);
    _trophyController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await Future.delayed(const Duration(seconds: 5));
        if (mounted) {
          _trophyController.forward(from: 0);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logBattleResultsViewed(battleCode: widget.battleCode);
      LocalStorageService.clearActiveBattleCode();
    });
  }

  @override
  void dispose() {
    _trophyController.dispose();
    super.dispose();
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
      canPop: widget.fromHistory,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!widget.fromHistory) {
          _goToHome();
        }
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
            onPressed: widget.fromHistory ? () => context.pop() : _goToHome,
          ),
        ),
        body: resultAsync.when(
          data: (result) {
            if (result == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28.r,
                      height: 28.r,
                      child: const CircularProgressIndicator(
                        color: AppColors.gold,
                        strokeWidth: 2.5,
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg.h),
                    Text(
                      isBn ? 'ফলাফল তৈরি হচ্ছে...' : 'Generating results...',
                      style: AppTextStyles.titleMedium(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Determine outcome
            String headerText;
            String subText;
            Color headerColor;
            IconData headerIcon;

            if (result.winnerUid == null) {
              headerText = isBn ? 'ড্র!' : 'Draw!';
              subText = isBn ? 'দুর্দান্ত লড়াই ছিল' : 'A well-matched battle';
              headerColor = AppColors.ice;
              headerIcon = Icons.handshake_rounded;
            } else if (result.winnerUid == currentUid) {
              headerText = isBn ? 'বিজয়ী!' : 'Victory!';
              subText = isBn ? 'দারুণ খেলেছেন' : 'Well played';
              headerColor = AppColors.gold;
              headerIcon = Icons.emoji_events_rounded;
            } else {
              headerText = isBn ? 'পরাজিত' : 'Defeat';
              subText = isBn ? 'পরের বার আরও ভালো হবে' : 'Better luck next time';
              headerColor = AppColors.danger;
              headerIcon = Icons.sentiment_dissatisfied_rounded;
            }

            final myResult = result.players.firstWhere(
              (p) => p.uid == currentUid,
              orElse: () => result.players.first,
            );
            final questions = result.questions;

            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(0, AppSpacing.lg.h, 0, AppSpacing.xxl.h),
                        sliver: SliverToBoxAdapter(
                          child: _buildResultHeader(
                            context: context,
                            headerText: headerText,
                            subText: subText,
                            headerColor: headerColor,
                            headerIcon: headerIcon,
                            score: myResult.score,
                            isWinner: result.winnerUid == currentUid,
                            trophyController: _trophyController,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            _sectionTitle(context, isBn ? 'লিডারবোর্ড' : 'Leaderboard', Icons.leaderboard_rounded),
                            SizedBox(height: AppSpacing.md.h),
                            _buildLeaderboard(context, result.players, currentUid, isBn),
                          ],
                        ),
                      ),

                      
                      if (questions.isNotEmpty) ...[
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 0),
                          sliver: SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: AppSpacing.md.h, bottom: AppSpacing.md.h),
                              child: _sectionTitle(
                                context,
                                isBn ? 'প্রশ্ন ও উত্তর' : 'Questions & Answers',
                                Icons.question_answer_rounded,
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final entry = questions[index];
                                final qId = entry['id'];
                                final userAnswer = myResult.answers.firstWhere(
                                  (a) => a['questionId'] == qId,
                                  orElse: () => <String, dynamic>{},
                                );
                                return Padding(
                                  padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                                  child: _buildQuestionCard(
                                    context, 
                                    index, 
                                    entry, 
                                    isBn, 
                                    userAnswer.isEmpty ? null : userAnswer,
                                  ),
                                );
                              },
                              childCount: (questions.length > 2 && !_isQuestionsExpanded) ? 2 : questions.length,
                            ),
                          ),
                        ),
                        if (questions.length > 2 && !_isQuestionsExpanded)
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
                            sliver: SliverToBoxAdapter(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isQuestionsExpanded = true;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: AppSpacing.md.h),
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.cardDark,
                                    borderRadius: BorderRadius.circular(AppRadius.lg.r),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isBn ? 'আরো দেখুন' : 'See More',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.textPrimary,
                                        size: 18.r,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                      SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.lg.h), // Bottom spacer
                      ),
                    ],
                  ),
                ),
                _buildFixedBottomButton(context, isBn),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
          error: (e, st) => Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
              padding: EdgeInsets.all(AppSpacing.lg.r),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(AppRadius.lg.r),
                border: Border.all(color: AppColors.danger.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20.r),
                  SizedBox(width: AppSpacing.sm.w),
                  Flexible(
                    child: Text(
                      'Error: $e',
                      style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Section header ----------

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 18.r),
        SizedBox(width: AppSpacing.sm.w),
        Text(title, style: AppTextStyles.titleLarge(context)),
      ],
    );
  }

  // ---------- Result header ----------

  Widget _buildResultHeader({
    required BuildContext context,
    required String headerText,
    required String subText,
    required Color headerColor,
    required IconData headerIcon,
    required int score,
    required bool isWinner,
    required AnimationController trophyController,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isWinner)
          Positioned.fill(
            child: Lottie.asset(
              'assets/lottie/success.json',
              repeat: false,
              fit: BoxFit.cover,
            ),
          ),
        Column(
          children: [
            Container(
              width: 96.r,
              height: 96.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [headerColor.withOpacity(0.28), headerColor.withOpacity(0.05)],
                ),
                border: Border.all(color: headerColor.withOpacity(0.5), width: 1.5),
              ),
              child: isWinner
                  ? Lottie.asset(
                      'assets/lottie/trophy.json',
                      controller: trophyController,
                      onLoaded: (composition) {
                        trophyController.duration = composition.duration;
                        trophyController.forward();
                      },
                      fit: BoxFit.contain,
                    )
                  : Icon(headerIcon, color: headerColor, size: 44.r),
            ),
            SizedBox(height: AppSpacing.lg.h),
        Text(
          headerText,
          style: AppTextStyles.displayMedium(context).copyWith(
            color: headerColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.xs.h),
        Text(
          subText,
          style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textMuted),
        ),
        SizedBox(height: AppSpacing.lg.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w, vertical: AppSpacing.sm.h),
          decoration: BoxDecoration(
            color: AppColors.goldCard,
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
            border: Border.all(color: AppColors.goldBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.gold, size: 16.r),
              SizedBox(width: AppSpacing.xs.w),
              Text(
                AppLocalizations.of(context)!.battleXpEarned(score),
                style: AppTextStyles.titleMedium(context).copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ],
);
}

  // ---------- Leaderboard ----------

  Widget _buildLeaderboard(BuildContext context, List<dynamic> players, String? currentUid, bool isBn) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
        child: Column(
          children: List.generate(players.length, (index) {
            final p = players[index];
            final isMe = p.uid == currentUid;
            final isLast = index == players.length - 1;

            return Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w, vertical: AppSpacing.md.h),
              decoration: BoxDecoration(
                color: isMe ? AppColors.goldCard : Colors.transparent,
                border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26.r,
                    height: 26.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == 0 ? AppColors.gold : AppColors.cardDark,
                      border: index == 0 ? null : Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: index == 0 ? AppColors.emeraldDeep : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md.w),
                  AvatarChip(
                    initial: p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                    color: isMe ? AppColors.gold : AppColors.ice,
                  ),
                  SizedBox(width: AppSpacing.md.w),
                  Expanded(
                    child: Text(
                      isMe ? (isBn ? '${p.name} (আপনি)' : '${p.name} (You)') : p.name,
                      style: AppTextStyles.titleMedium(context).copyWith(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        color: isMe ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md.w),
                  Column(  crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${p.score} pts',
                        style: AppTextStyles.titleSmall(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${(p.totalTimeMs / 1000).toStringAsFixed(1)}s',
                        style: AppTextStyles.labelSmall(context).copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // ---------- Question review ----------

  Widget _buildQuestionCard(BuildContext context, int i, dynamic q, bool isBn, Map<String, dynamic>? userAnswer) {
    final text = q['text'];
    final explanation = q['explanation'];
    final correctIndex = q['correctIndex'] as int?;
    final rawOptions = q['options'];
    final options = rawOptions is Iterable ? List<String>.from(rawOptions) : <String>[];
    final userSelectedIndex = userAnswer?['selectedIndex'] as int?;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.r),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24.r,
                height: 24.r,
                alignment: Alignment.center,
                margin: EdgeInsets.only(top: 2.h),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldCard,
                  border: Border.all(color: AppColors.goldBorder),
                ),
                child: Text(
                  '${i + 1}',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.titleMedium(context).copyWith(height: 1.4),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          ...options.asMap().entries.map((optionEntry) {
            final optionIndex = optionEntry.key;
            final optionText = optionEntry.value;

            final isCorrect = optionIndex == correctIndex;
            final isSelected = optionIndex == userSelectedIndex;

            Color bgColor = Colors.transparent;
            Color borderColor = AppColors.cardBorder;
            Color textColor = AppColors.textPrimary;
            IconData? icon;
            Color? iconColor;

            if (isCorrect) {
              bgColor = AppColors.successLight;
              borderColor = AppColors.success.withOpacity(0.35);
              textColor = AppColors.success;
              icon = Icons.check_circle_rounded;
              iconColor = AppColors.success;
            } else if (isSelected) {
              bgColor = AppColors.dangerLight;
              borderColor = AppColors.danger.withOpacity(0.35);
              textColor = AppColors.danger;
              icon = Icons.cancel_rounded;
              iconColor = AppColors.danger;
            } else {
              // Add a subtle border/bg for unselected options
              bgColor = Colors.transparent;
              borderColor = AppColors.cardBorder.withOpacity(0.5);
              textColor = AppColors.textPrimary;
            }

            return Container(
              margin: EdgeInsets.only(bottom: AppSpacing.sm.h),
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: AppSpacing.sm.h),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppRadius.md.r),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: iconColor, size: 18.r),
                    SizedBox(width: AppSpacing.sm.w),
                  ] else ...[
                    SizedBox(width: 22.w), // alignment placeholder
                  ],
                  Expanded(
                    child: Text(
                      optionText,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: textColor,
                        fontWeight: (isCorrect || isSelected) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (explanation != null && explanation.toString().isNotEmpty) ...[
            SizedBox(height: AppSpacing.md.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: AppColors.textMuted, size: 16.r),
                SizedBox(width: AppSpacing.sm.w),
                Expanded(
                  child: Text(
                    explanation,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------- Fixed bottom "Play Again" button ----------

  Widget _buildFixedBottomButton(BuildContext context, bool isBn) {
    return Container(
      padding: EdgeInsets.fromLTRB(
       0,
        AppSpacing.md.h,
        0,
        AppSpacing.md.h,
      ),
      child: SafeArea(
        top: false,
        child: _buildPlayAgainButton(context, isBn),
      ),
    );
  }

  // ---------- Play again button ----------

  Widget _buildPlayAgainButton(BuildContext context, bool isBn) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.goldLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
          onTap: _goToHome,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.h),
            child: Center(
              child: Text(
                isBn ? 'আবার খেলুন' : 'Play Again',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.emeraldDeep,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}