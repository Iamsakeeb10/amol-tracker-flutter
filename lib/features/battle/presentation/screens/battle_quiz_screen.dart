import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import '../../../syllabus/presentation/widgets/quiz_option_tile.dart';
import '../../../syllabus/presentation/widgets/quiz_helpers.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../providers/leaderboard_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/battle_providers.dart';
import '../../models/battle_model.dart';
import '../../models/question_report_model.dart';
import '../../repositories/question_report_repository.dart';
import '../../exceptions/battle_api_exception.dart';

class BattleQuizScreen extends ConsumerStatefulWidget {
  final String battleCode;

  const BattleQuizScreen({super.key, required this.battleCode});

  @override
  ConsumerState<BattleQuizScreen> createState() => _BattleQuizScreenState();
}

class _BattleQuizScreenState extends ConsumerState<BattleQuizScreen> {
  Timer? _timer;
  Timer? _serverDelayTimer;
  int _timeLeftMs = 0;
  
  bool _isNavigatingToResults = false;

  int _uiQuestionIndex = 0;
  
  // Local state for the current question
  int? _selectedIndex;
  bool _isTransitioning = false;
  
  // Overall state for finishing
  Stopwatch? _globalStopwatch;
  Stopwatch? _questionStopwatch;
  
  bool _hasFinishedLocal = false;
  bool _isSubmittingAll = false;
  bool _isServerDelayed = false;
  
  // Answers list to send to backend at the end
  final List<Map<String, dynamic>> _myAnswers = [];

  @override
  void dispose() {
    _timer?.cancel();
    _serverDelayTimer?.cancel();
    super.dispose();
  }

  void _startTimer(DateTime startedAt, int timeLimitSeconds) {
    if (_timer != null) return;
    
    _globalStopwatch = Stopwatch()..start();
    _questionStopwatch = Stopwatch()..start();
    
    // Calculate elapsed time on server
    final serverElapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
    final totalLimitMs = timeLimitSeconds * 1000;
    final initialRemaining = totalLimitMs - serverElapsedMs;
    
    if (initialRemaining <= 0) {
      _timeLeftMs = 0;
      _triggerFinish();
      return;
    }

    setState(() {
      _timeLeftMs = initialRemaining;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final localElapsedMs = _globalStopwatch?.elapsedMilliseconds ?? 0;
      final remaining = initialRemaining - localElapsedMs;
      
      setState(() {
        _timeLeftMs = remaining > 0 ? remaining : 0;
      });
      
      if (remaining <= 0) {
        timer.cancel();
        _triggerFinish();
        
        // Start delay timer instead of fallback/forfeit timer
        _serverDelayTimer = Timer(const Duration(seconds: 15), () {
          if (mounted && _hasFinishedLocal) {
            setState(() {
              _isServerDelayed = true;
            });
          }
        });
      }
    });
  }

  void _handleOptionSelected(int index, Map<String, dynamic> qData, int totalQuestions) async {
    if (_selectedIndex != null || _isTransitioning || _hasFinishedLocal) return;

    final qId = qData['id'] as String;
    final responseTimeMs = _questionStopwatch?.elapsedMilliseconds ?? 0;
    
    setState(() {
      _selectedIndex = index;
      _isTransitioning = true;
    });
    
    _myAnswers.add({
      'questionId': qId,
      'selectedIndex': index,
      'responseTimeMs': responseTimeMs,
    });

    // Wait 600ms so user can see right/wrong feedback quickly
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (!mounted) return;

    if (_uiQuestionIndex >= totalQuestions - 1) {
      // Finished all questions
      _triggerFinish();
    } else {
      // Next question
      setState(() {
        _uiQuestionIndex++;
        _selectedIndex = null;
        _isTransitioning = false;
      });
      _questionStopwatch = Stopwatch()..start();
    }
  }

  Future<void> _triggerFinish() async {
    if (_hasFinishedLocal) return;
    
    setState(() {
      _hasFinishedLocal = true;
      _isSubmittingAll = true;
    });

    try {
      final repo = ref.read(battleRepositoryProvider);
      await repo.submitAllAnswers(
        code: widget.battleCode,
        answers: _myAnswers,
      );
      if (mounted) {
        int totalScore = 0;
        for (final a in _myAnswers) {
          totalScore += (a['points'] as int?) ?? 0;
        }
        AnalyticsService.instance.logBattleQuizCompleted(
          battleCode: widget.battleCode,
          score: totalScore,
        );

        setState(() {
          _isSubmittingAll = false;
        });
      }
    } catch (e, st) {
      AnalyticsService.instance.recordError(e, st, reason: 'Failed to submit battle answers');
      debugPrint('Failed to submit all answers: $e');
      if (mounted) {
        setState(() {
          _isSubmittingAll = false;
        });
        
        String errorMessage = 'Failed to submit answers. Result might be lost.';
        if (e is BattleApiException) {
          errorMessage = e.message;
        } else if (e is FormatException) {
          // Ignored if it's just a parsing error that made it through
          return;
        } else {
          errorMessage = e.toString();
        }

        // We could show a retry button, but for now just show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _handleExit(BuildContext context) {
    try {
      final repo = ref.read(battleRepositoryProvider);
      repo.leaveBattle(code: widget.battleCode).catchError((e) {
        debugPrint('Failed to leave battle: $e');
      });
      AnalyticsService.instance.logBattleForfeited(battleCode: widget.battleCode);
    } catch (e, st) {
      AnalyticsService.instance.recordError(e, st, reason: 'Failed to forfeit battle');
      debugPrint('Failed to leave battle: $e');
    }
    context.go(AppRoutes.home);
  }

  void _showReportBottomSheet(Map<String, dynamic> qData, AppLocalizations l10n) {
    final reasons = ['Wrong Answer', 'Typo/Grammar', 'Inappropriate', 'Other'];
    String selectedReason = reasons.first;
    final detailsController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
                decoration: BoxDecoration(
                  color: AppColors.emeraldDeep,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: AppColors.danger),
                          ),
                          child: Icon(Icons.flag_rounded, color: AppColors.danger, size: 18.r),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            l10n.reportQuestion,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l10n.selectReason,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  SizedBox(height: 8.h),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    dropdownColor: AppColors.cardDark,
                    items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) setStateSheet(() => selectedReason = val);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.cardDark,
                      contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: detailsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.reportDetails,
                      filled: true,
                      fillColor: AppColors.cardDark,
                      contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setStateSheet(() => isSubmitting = true);
                            try {
                              final user = ref.read(currentUserProvider).value;
                              final report = QuestionReportModel(
                                id: '',
                                questionId: qData['id'] as String? ?? '',
                                questionText: qData['text'] as String? ?? '',
                                reportedByUserId: user?.uid ?? '',
                                reportedByUserName: user?.name ?? 'Unknown',
                                reason: selectedReason,
                                details: detailsController.text,
                                createdAt: DateTime.now(),
                              );
                              await ref.read(questionReportRepositoryProvider).submitReport(report);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Report submitted successfully!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e, st) {
                              AnalyticsService.instance.recordError(e, st, reason: 'Failed to submit question report in battle');
                              setStateSheet(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to submit report')),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: isSubmitting
                        ? SizedBox(height: 20.r, width: 20.r, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(l10n.submitReport, style: AppTextStyles.button(context).copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).languageCode;
    final isBn = locale == 'bn';
    final battleAsync = ref.watch(battleStreamProvider(widget.battleCode));
    final questionsAsync = ref.watch(battleQuestionsProvider(widget.battleCode));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => _BattleExitDialog(isBn: isBn),
        );
        if (shouldExit == true && context.mounted) {
          _handleExit(context);
        }
      },
      child: AppScaffold(
        handleExitBack: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            isBn ? 'নলেজ ব্যাটেল' : 'Knowledge Battle',
            style: AppTextStyles.headlineMedium(context),
          ),
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: IconButton(
                icon: Icon(
                  Icons.exit_to_app_rounded,
                  color: AppColors.danger,
                  size: 26.r,
                ),
                onPressed: () async {
                  final shouldExit = await showDialog<bool>(
                    context: context,
                    builder: (_) => _BattleExitDialog(isBn: isBn),
                  );
                  if (shouldExit == true && context.mounted) {
                    _handleExit(context);
                  }
                },
              ),
            ),
          ],
        ),
      body: battleAsync.when(
        data: (battle) {
          if (battle == null) {
            return const Center(child: Text('Battle not found'));
          }

          if (battle.status == 'finished') {
            if (!_isNavigatingToResults) {
              _isNavigatingToResults = true;
              // Invalidate battle leaderboard so it refreshes with latest scores
              ref.invalidate(battleLeaderboardProvider);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.pushReplacement(AppRoutes.battleResultsPath(widget.battleCode));
                }
              });
            }
            return const SizedBox.shrink();
          }

          final questions = questionsAsync.value ?? [];
          
          if (questions.isEmpty) {
            if (questionsAsync.isLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            }
            return Center(
              child: Text(
                isBn ? 'প্রশ্ন লোড করতে ব্যর্থ হয়েছে।' : 'Failed to load questions.',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          if (battle.startedAt != null) {
            _startTimer(battle.startedAt!, battle.timeLimitSeconds);
          }

          final currentQ = questions[_uiQuestionIndex];
          debugPrint('CURRENT Q DATA: $currentQ');
          final text = currentQ['text'] ?? '';
          final rawOptions = currentQ['options'];
          final options = rawOptions is Iterable 
              ? List<String>.from(rawOptions.map((e) => e?.toString() ?? ''))
              : <String>[];
          final correctIndex = currentQ['correctIndex'] as int? ?? 0;
          
          final sourceRef = currentQ['sourceReference'];
          final hasSource = sourceRef != null && sourceRef.toString().isNotEmpty;

          final timeIsUp = _timeLeftMs <= 0;
          
          // If finished local, the progress bar should show fully complete if they answered all,
          // or partial if time ran out. We use min() to ensure it doesn't exceed 1.0.
          final progressValue = _hasFinishedLocal && !timeIsUp 
              ? 1.0 
              : quizProgressValue(_uiQuestionIndex, questions.length);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 12.h),
              // Timer Area
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16.r,
                    color: timeIsUp ? AppColors.danger : AppColors.goldLight,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    isBn ? 'সময় বাকি' : 'Time Remaining',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatQuizDuration((_timeLeftMs / 1000).ceil()),
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: timeIsUp ? AppColors.danger : AppColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ScoreBar(
                value: _timeLeftMs / (battle.timeLimitSeconds * 1000),
                height: 6,
                color: timeIsUp ? AppColors.danger : AppColors.gold,
              ),
              SizedBox(height: 16.h),
              
              // Progress Area
              Text(
                isBn 
                    ? 'প্রশ্ন ${_uiQuestionIndex + 1} / ${questions.length}'
                    : 'Question ${_uiQuestionIndex + 1} of ${questions.length}',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: 6.h),
              ScoreBar(
                value: progressValue,
                height: 6,
              ),
              SizedBox(height: 16.h),

              if (_hasFinishedLocal)
                Expanded(
                  child: Center(
                    child: CardContainer(
                      padding: EdgeInsets.all(32.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            timeIsUp ? Icons.timer_off_rounded : Icons.check_circle_rounded, 
                            color: timeIsUp ? AppColors.danger : AppColors.success, 
                            size: 48.r
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            timeIsUp 
                                ? (isBn ? 'সময় শেষ!' : 'Time is up!')
                                : (isBn ? 'সবগুলো প্রশ্নের উত্তর দেওয়া হয়েছে!' : 'All questions answered!'),
                            style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24.h),
                          if (_isSubmittingAll) ...[
                            const CircularProgressIndicator(color: AppColors.gold),
                            SizedBox(height: 16.h),
                            Text(
                              isBn ? 'আপনার উত্তর সাবমিট হচ্ছে...' : 'Submitting answers...',
                              style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
                            ),
                          ] else ...[
                            const CircularProgressIndicator(color: AppColors.ice),
                            SizedBox(height: 16.h),
                            Text(
                              timeIsUp 
                                  ? (_isServerDelayed 
                                      ? (isBn ? 'সার্ভার থেকে উত্তরের জন্য অপেক্ষা করা হচ্ছে...' : 'Server is taking longer than expected...')
                                      : (isBn ? 'অন্যান্য প্রতিযোগীদের জন্য অপেক্ষা করা হচ্ছে...' : 'Waiting for opponents to finish...'))
                                  : (isBn ? 'অনুগ্রহ করে বাকিদের শেষ হওয়া পর্যন্ত অপেক্ষা করুন...' : 'Please wait while your opponents finish...'),
                              style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                // Question Text
                CardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isBn ? 'প্রশ্ন' : 'Question',
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          InkWell(
                            onTap: () => _showReportBottomSheet(currentQ, AppLocalizations.of(context)!),
                            child: Icon(Icons.flag_outlined, size: 20.r, color: AppColors.textMuted),
                          )
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        text,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasSource) ...[
                        SizedBox(height: 12.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.menu_book_rounded, size: 14.r, color: AppColors.goldLight),
                            SizedBox(width: 6.w),
                            Expanded(
  child: Transform.translate(
    offset: const Offset(0, -1),
    child: Text(
      '${AppLocalizations.of(context)!.source}: $sourceRef',
      style: AppTextStyles.bodySmall(context).copyWith(
        color: AppColors.goldLight,
        fontStyle: FontStyle.italic,
        height: 0,
      ),
    ),
  ),
),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // Options
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final isSelectedByMe = _selectedIndex == index;
                      
                      QuizOptionTileState tileState = QuizOptionTileState.idle;
                      
                      // Show correct/wrong instantly if selected
                      if (_selectedIndex != null) {
                        if (index == correctIndex) {
                          tileState = QuizOptionTileState.correct;
                        } else if (isSelectedByMe) {
                          tileState = QuizOptionTileState.wrong;
                        }
                      }

                      return Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: QuizOptionTile(
                          index: index,
                          label: options[index],
                          state: tileState,
                          enabled: _selectedIndex == null,
                          onTap: () => _handleOptionSelected(index, currentQ, questions.length),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    ));
  }
}

class _BattleExitDialog extends StatelessWidget {
  final bool isBn;
  const _BattleExitDialog({required this.isBn});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.emeraldDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: AppColors.goldBorder, width: 1.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.dangerLight.withOpacity(0.1),
                border: Border.all(color: AppColors.danger, width: 1.r),
              ),
              child: Icon(
                Icons.exit_to_app_rounded,
                color: AppColors.danger,
                size: 26.r,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              isBn ? 'ব্যাটেল থেকে বের হতে চান?' : 'Exit Battle?',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium(context).copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              isBn
                  ? 'বের হয়ে গেলে আপনি এই ব্যাটেলে হেরে যাবেন (ফরফিট)।'
                  : 'If you leave, you will forfeit this battle.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      side: BorderSide(color: AppColors.goldBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      isBn ? 'থাকুন' : 'Stay',
                      style: AppTextStyles.button(context).copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isBn ? 'বের হোন' : 'Leave',
                      style: AppTextStyles.button(context).copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
