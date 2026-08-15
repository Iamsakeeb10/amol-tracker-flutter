import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import '../../../syllabus/presentation/widgets/quiz_option_tile.dart';
import '../../../syllabus/presentation/widgets/quiz_helpers.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../providers/battle_providers.dart';
import '../../models/battle_model.dart';

class BattleQuizScreen extends ConsumerStatefulWidget {
  final String battleCode;

  const BattleQuizScreen({super.key, required this.battleCode});

  @override
  ConsumerState<BattleQuizScreen> createState() => _BattleQuizScreenState();
}

class _BattleQuizScreenState extends ConsumerState<BattleQuizScreen> {
  int _uiQuestionIndex = 0;
  
  // Local state for the current question
  int? _selectedIndex;
  bool _isTransitioning = false;
  
  // Time and submission state
  Timer? _timer;
  Stopwatch? _globalStopwatch;
  Stopwatch? _questionStopwatch;
  int _timeLeftMs = 0;
  
  bool _hasFinishedLocal = false;
  bool _isSubmittingAll = false;
  
  // Answers list to send to backend at the end
  final List<Map<String, dynamic>> _myAnswers = [];

  @override
  void dispose() {
    _timer?.cancel();
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
      }
    });
  }

  void _handleOptionSelected(int index, Map<String, dynamic> qData, int totalQuestions) async {
    if (_selectedIndex != null || _isTransitioning || _hasFinishedLocal || _timeLeftMs <= 0) return;

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

    // Wait 1.5 seconds so user can see right/wrong feedback
    await Future.delayed(const Duration(milliseconds: 1500));
    
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
    _timer?.cancel();

    try {
      final repo = ref.read(battleRepositoryProvider);
      await repo.submitAllAnswers(
        code: widget.battleCode,
        answers: _myAnswers,
      );
      if (mounted) {
        setState(() {
          _isSubmittingAll = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to submit all answers: $e');
      if (mounted) {
        setState(() {
          _isSubmittingAll = false;
        });
        // We could show a retry button, but for now just show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit answers. Result might be lost.'),
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
    } catch (e) {
      debugPrint('Failed to leave battle: $e');
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).languageCode;
    final isBn = locale == 'bn';
    final battleAsync = ref.watch(battleStreamProvider(widget.battleCode));

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
                  color: const Color(0xFFFF5252),
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.pushReplacement(AppRoutes.battleResultsPath(widget.battleCode));
              }
            });
            return const SizedBox.shrink();
          }

          final questions = battle.questionsData ?? [];
          
          if (questions.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }

          if (battle.startedAt != null) {
            _startTimer(battle.startedAt!, battle.timeLimitSeconds);
          }

          final currentQ = questions[_uiQuestionIndex];
          final text = currentQ['text'] ?? '';
          final rawOptions = currentQ['options'] ?? [];
          final options = List<String>.from(rawOptions);
          final correctIndex = currentQ['correctIndex'] as int? ?? 0;
          
          final timeIsUp = _timeLeftMs <= 0;
          
          // If finished local, the progress bar should show fully complete if they answered all,
          // or partial if time ran out. We use min() to ensure it doesn't exceed 1.0.
          final progressValue = _hasFinishedLocal && !timeIsUp 
              ? 1.0 
              : quizProgressValue(_uiQuestionIndex, questions.length);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                                : (isBn ? 'দুর্দান্ত! আপনি সবগুলো প্রশ্নের উত্তর দিয়েছেন।' : 'Great job! You finished all questions.'),
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
                              isBn ? 'অন্যান্য প্রতিযোগীদের জন্য অপেক্ষা করা হচ্ছে...' : 'Waiting for opponents to finish...',
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
                      Text(
                        isBn ? 'প্রশ্ন' : 'Question',
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        text,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                color: AppColors.dangerLight,
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
