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
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../providers/battle_providers.dart';
import '../../exceptions/battle_api_exception.dart';

class BattleQuizScreen extends ConsumerStatefulWidget {
  final String battleCode;

  const BattleQuizScreen({super.key, required this.battleCode});

  @override
  ConsumerState<BattleQuizScreen> createState() => _BattleQuizScreenState();
}

class _BattleQuizScreenState extends ConsumerState<BattleQuizScreen> {
  int _uiQuestionIndex = 0;
  bool _isTransitioning = false;
  
  // Local state for the current question
  int? _selectedIndex;
  bool _isSubmitting = false;
  bool? _isCorrect; // From submitAnswer response
  
  Timer? _timer;
  int _timeLeftMs = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(DateTime revealedAt, int secondsPerQuestion) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      final elapsedMs = DateTime.now().difference(revealedAt).inMilliseconds;
      final remaining = (secondsPerQuestion * 1000) - elapsedMs;
      setState(() {
        _timeLeftMs = remaining > 0 ? remaining : 0;
      });
      if (remaining <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _submitAnswer(int index) async {
    if (_selectedIndex != null || _isSubmitting || _timeLeftMs <= 0) return;

    setState(() {
      _selectedIndex = index;
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(battleRepositoryProvider);
      final res = await repo.submitAnswer(
        code: widget.battleCode,
        selectedIndex: index,
        // Calculate response time based on local elapsed time since reveal
        // The backend calculates its own and uses it, but we send it anyway
        responseTimeMs: 0, 
      );
      
      if (mounted) {
        setState(() {
          _isCorrect = res.isCorrect;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedIndex = null; // allow them to try again if it failed
        });
        
        final locale = ref.read(localeProvider).languageCode;
        final isBn = locale == 'bn';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBn ? 'নেটওয়ার্ক সমস্যা, আবার চেষ্টা করুন!' : 'Network error, please try again!',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _nextQuestion() async {
    try {
      final repo = ref.read(battleRepositoryProvider);
      await repo.nextQuestion(code: widget.battleCode);
    } catch (e) {
      debugPrint('Next question failed: $e');
      if (mounted) {
        final locale = ref.read(localeProvider).languageCode;
        final isBn = locale == 'bn';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBn ? 'এখনো সময় শেষ হয়নি অথবা নেটওয়ার্ক সমস্যা!' : 'Time not up yet or network error!',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).languageCode;
    final isBn = locale == 'bn';
    final battleAsync = ref.watch(battleStreamProvider(widget.battleCode));
    final currentUser = ref.watch(currentUserProvider).asData?.value;

    return AppScaffold(
      handleExitBack: true, // Allow exiting, but maybe warn in real app
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isBn ? 'নলেজ ব্যাটেল' : 'Knowledge Battle',
          style: AppTextStyles.headlineMedium(context),
        ),
        automaticallyImplyLeading: false, // Hide back button during quiz
      ),
      body: battleAsync.when(
        data: (battle) {
          if (battle == null) return const Center(child: Text('Battle not found'));

          if (battle.status == 'finished') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.pushReplacement(AppRoutes.battleResultsPath(widget.battleCode));
              }
            });
            return const SizedBox.shrink();
          }

          final serverIndex = battle.currentQuestionIndex;
          
          // Detect advancement and trigger 3-second delay
          if (serverIndex > _uiQuestionIndex && !_isTransitioning) {
            _isTransitioning = true;
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _uiQuestionIndex = serverIndex;
                  _selectedIndex = null;
                  _isCorrect = null;
                  _isTransitioning = false;
                  
                  // Restart timer for the new question
                  if (battle.questionRevealedAt != null) {
                    _startTimer(battle.questionRevealedAt!, battle.secondsPerQuestion);
                  }
                });
              }
            });
          }

          // Initial timer start
          if (_timer == null && battle.questionRevealedAt != null && !_isTransitioning) {
            _startTimer(battle.questionRevealedAt!, battle.secondsPerQuestion);
          }

          final isHost = currentUser?.uid == battle.hostUid;
          
          // Determine which question to show based on _uiQuestionIndex
          // If we are transitioning, we show the OLD question (which we don't have perfectly 
          // because battle.currentQuestion has already updated to the next one).
          // Wait, if battle.currentQuestion is the NEW question, we can't show the old one!
          // Ah. The Worker overwrote `currentQuestion`. We MUST use local state to cache the question!
          
          return _QuizContent(
            battleCode: widget.battleCode,
            battle: battle,
            isHost: isHost,
            isBn: isBn,
            locale: locale,
            uiIndex: _uiQuestionIndex,
            isTransitioning: _isTransitioning,
            timeLeftMs: _timeLeftMs,
            selectedIndex: _selectedIndex,
            isCorrect: _isCorrect,
            isSubmitting: _isSubmitting,
            onSubmit: _submitAnswer,
            onNext: _nextQuestion,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _QuizContent extends StatefulWidget {
  final String battleCode;
  final dynamic battle;
  final bool isHost;
  final bool isBn;
  final String locale;
  final int uiIndex;
  final bool isTransitioning;
  final int timeLeftMs;
  final int? selectedIndex;
  final bool? isCorrect;
  final bool isSubmitting;
  final ValueChanged<int> onSubmit;
  final VoidCallback onNext;

  const _QuizContent({
    required this.battleCode,
    required this.battle,
    required this.isHost,
    required this.isBn,
    required this.locale,
    required this.uiIndex,
    required this.isTransitioning,
    required this.timeLeftMs,
    required this.selectedIndex,
    required this.isCorrect,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onNext,
  });

  @override
  State<_QuizContent> createState() => _QuizContentState();
}

class _QuizContentState extends State<_QuizContent> {
  // Cache the question being displayed so it doesn't instantly swap when server advances
  Map<String, dynamic>? _cachedQuestion;
  int _cachedIndex = -1;

  @override
  void didUpdateWidget(_QuizContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only update cache if we are NOT transitioning
    if (!widget.isTransitioning && widget.battle.currentQuestion != null) {
      if (_cachedIndex != widget.uiIndex || _cachedQuestion == null) {
        _cachedQuestion = widget.battle.currentQuestion;
        _cachedIndex = widget.uiIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initial cache populate
    if (_cachedQuestion == null && widget.battle.currentQuestion != null) {
      _cachedQuestion = widget.battle.currentQuestion;
      _cachedIndex = widget.uiIndex;
    }

    final question = _cachedQuestion;
    if (question == null) {
      return Center(
        child: Text(
          widget.isBn ? 'প্রস্তুত হোন...' : 'Get ready...',
          style: AppTextStyles.titleMedium(context),
        ),
      );
    }

    final qId = question['id'] as String;
    // Safely fallback to English if Bengali is missing (common for test data)
    final text = (widget.isBn ? question['textBn'] : question['textEn']) ?? question['textEn'] ?? '';
    
    final rawOptions = (widget.isBn ? question['optionsBn'] : question['optionsEn']) ?? question['optionsEn'] ?? [];
    final options = List<String>.from(rawOptions);
    
    // Determine if we are in "revealed" state (either transitioning or time is up)
    final timeIsUp = widget.timeLeftMs <= 0;
    final isRevealed = widget.isTransitioning || timeIsUp;
    
    // Get revealed answer from battle doc if available
    final revealedData = widget.battle.revealedAnswers?[qId];
    final globalCorrectIndex = revealedData?['correctIndex'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Bar: Question X of Y
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.isBn 
                  ? 'প্রশ্ন ${widget.uiIndex + 1} / ${widget.battle.questionCount}'
                  : 'Question ${widget.uiIndex + 1} / ${widget.battle.questionCount}',
              style: AppTextStyles.labelMedium(context).copyWith(color: AppColors.gold),
            ),
            // Timer
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.emeraldLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: timeIsUp ? AppColors.danger : AppColors.gold),
              ),
              child: Text(
                '${(widget.timeLeftMs / 1000).ceil()}s',
                style: AppTextStyles.titleSmall(context).copyWith(
                  color: timeIsUp ? AppColors.danger : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        // Progress Bar
        SizedBox(height: 12.h),
        LinearProgressIndicator(
          value: widget.timeLeftMs / (widget.battle.secondsPerQuestion * 1000),
          backgroundColor: AppColors.emeraldLight,
          color: AppColors.gold,
          minHeight: 6.h,
          borderRadius: BorderRadius.circular(3.r),
        ),

        SizedBox(height: 32.h),

        // Question Text
        CardContainer(
          padding: EdgeInsets.all(20.r),
          color: AppColors.emeraldMid,
          borderColor: AppColors.gold.withValues(alpha: 0.5),
          child: Text(
            text,
            style: AppTextStyles.titleLarge(context).copyWith(height: 1.4),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: 32.h),

        // Options
        Expanded(
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              return Consumer(
                builder: (context, ref, child) {
                  // Fetch answers for this question to show avatars when revealed
                  final answersAsync = ref.watch(battleAnswersProvider((code: widget.battleCode, questionId: qId)));
                  final allAnswers = answersAsync.value ?? [];
                  final playersWhoPickedThis = allAnswers.where((a) => a.selectedIndex == index).toList();

                  // Determine colors
                  final isSelectedByMe = widget.selectedIndex == index;
                  
                  Color bgColor = AppColors.emeraldLight.withValues(alpha: 0.3);
                  Color borderColor = AppColors.emeraldLight;
                  Color textColor = AppColors.textPrimary;

                  if (isRevealed && globalCorrectIndex != null) {
                    if (index == globalCorrectIndex) {
                      bgColor = AppColors.success.withValues(alpha: 0.2);
                      borderColor = AppColors.success;
                      textColor = AppColors.success;
                    } else if (isSelectedByMe) {
                      bgColor = AppColors.danger.withValues(alpha: 0.2);
                      borderColor = AppColors.danger;
                      textColor = AppColors.danger;
                    } else {
                      textColor = AppColors.textMuted;
                    }
                  } else if (isSelectedByMe) {
                    if (widget.isCorrect == true) {
                      bgColor = AppColors.success.withValues(alpha: 0.2);
                      borderColor = AppColors.success;
                    } else if (widget.isCorrect == false) {
                      bgColor = AppColors.danger.withValues(alpha: 0.2);
                      borderColor = AppColors.danger;
                    } else {
                      bgColor = AppColors.gold.withValues(alpha: 0.2);
                      borderColor = AppColors.gold;
                    }
                  }

                  return InkWell(
                    onTap: () => widget.onSubmit(index),
                    borderRadius: BorderRadius.circular(12.r),
                    child: CardContainer(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      color: bgColor,
                      borderColor: borderColor,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              options[index],
                              style: AppTextStyles.bodyLarge(context).copyWith(color: textColor),
                            ),
                          ),
                          if (isSelectedByMe && widget.isSubmitting)
                            SizedBox(
                              width: 20.r,
                              height: 20.r,
                              child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                            ),
                          if (isRevealed && playersWhoPickedThis.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: playersWhoPickedThis.map((a) {
                                return Padding(
                                  padding: EdgeInsets.only(left: 4.w),
                                  child: AvatarChip(
                                    initial: 'P', // Would be real initial if we joined user data
                                    color: AppColors.ice,
                                    size: 24.r,
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                }
              );
            },
          ),
        ),

        // Host Actions
        if (widget.isHost)
          Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: ElevatedButton(
              onPressed: (!isRevealed || widget.isTransitioning) ? null : widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.3),
                foregroundColor: AppColors.emeraldDeep,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(
                widget.uiIndex >= widget.battle.questionCount - 1
                    ? (widget.isBn ? 'ব্যাটেল শেষ করুন' : 'Finish Battle')
                    : (widget.isBn ? 'পরবর্তী প্রশ্ন' : 'Next Question'),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
