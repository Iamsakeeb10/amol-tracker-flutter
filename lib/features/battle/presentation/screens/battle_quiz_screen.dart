import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../../../shared/widgets/score_bar.dart';
import '../../../syllabus/presentation/widgets/quiz_option_tile.dart';
import '../../../syllabus/presentation/widgets/quiz_helpers.dart';
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
  
  bool _isAutoAdvancing = false;
  Timer? _autoAdvanceTimer;

  @override
  void dispose() {
    _timer?.cancel();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  Stopwatch? _stopwatch;

  void _startTimer(DateTime revealedAt, int secondsPerQuestion, bool isHost) {
    _timer?.cancel();
    _autoAdvanceTimer?.cancel();
    _stopwatch = Stopwatch()..start();
    
    final totalMs = secondsPerQuestion * 1000;
    
    setState(() {
      _timeLeftMs = totalMs;
      _isAutoAdvancing = false;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final elapsedMs = _stopwatch?.elapsedMilliseconds ?? 0;
      final remaining = totalMs - elapsedMs;
      
      setState(() {
        _timeLeftMs = remaining > 0 ? remaining : 0;
      });
      
      if (remaining <= 0) {
        timer.cancel();
        
        if (isHost && mounted && !_isAutoAdvancing) {
          setState(() {
            _isAutoAdvancing = true;
          });
          _autoAdvanceTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              _nextQuestion();
            }
          });
        }
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
        responseTimeMs: _stopwatch?.elapsedMilliseconds ?? 0, 
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
    _autoAdvanceTimer?.cancel();
    if (mounted && !_isAutoAdvancing) {
      setState(() {
        _isAutoAdvancing = true;
      });
    }

    try {
      final repo = ref.read(battleRepositoryProvider);
      await repo.nextQuestion(code: widget.battleCode);
    } catch (e) {
      debugPrint('Next question failed: $e');
      if (mounted) {
        setState(() {
          _isAutoAdvancing = false;
        });
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

  void _handleExit(BuildContext context) {
    try {
      final repo = ref.read(battleRepositoryProvider);
      repo.leaveBattle(code: widget.battleCode).catchError((e) {
        debugPrint('Failed to leave battle (background): $e');
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
    final currentUser = ref.watch(currentUserProvider).asData?.value;

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
        handleExitBack: false, // Handled by PopScope above
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
                  color: const Color(0xFFFF5252), // Explicit red color (Colors.redAccent)
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
          debugPrint('=== QUIZ SCREEN RENDER ===');
          if (battle == null) {
            debugPrint('Battle is null!');
            return const Center(child: Text('Battle not found'));
          }

          debugPrint('Battle Status: ${battle.status}');
          debugPrint('Question Count: ${battle.questionCount}');
          debugPrint('Current Question Index (Server): ${battle.currentQuestionIndex}');
          debugPrint('Current Question Data: ${battle.currentQuestion}');
          
          if (battle.currentQuestion != null && battle.currentQuestion!['id'] != null) {
            FirebaseFirestore.instance
                .collection('topics')
                .doc(battle.topicId)
                .collection('questions')
                .doc(battle.currentQuestion!['id'])
                .get()
                .then((doc) {
                  debugPrint('DIRECT FETCH from topics/${battle.topicId}/questions/${battle.currentQuestion!['id']}:');
                  debugPrint('${doc.data()}');
                }).catchError((e) => debugPrint('Error fetching doc: $e'));
          }

          if (battle.status == 'finished') {
            debugPrint('Battle finished, navigating to results...');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.pushReplacement(AppRoutes.battleResultsPath(widget.battleCode));
              }
            });
            return const SizedBox.shrink();
          }

          final serverIndex = battle.currentQuestionIndex;
          final isHost = currentUser?.uid == battle.hostUid;
          
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
                    _startTimer(battle.questionRevealedAt!, battle.secondsPerQuestion, isHost);
                  }
                });
              }
            });
          }

          // Initial timer start
          if (_timer == null && battle.questionRevealedAt != null && !_isTransitioning) {
            _startTimer(battle.questionRevealedAt!, battle.secondsPerQuestion, isHost);
          }
          
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
            isAutoAdvancing: _isAutoAdvancing,
            onSubmit: _submitAnswer,
            onNext: _nextQuestion,
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
  final bool isAutoAdvancing;
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
    required this.isAutoAdvancing,
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
    debugPrint('=== _QuizContent RENDER ===');
    debugPrint('widget.uiIndex: ${widget.uiIndex}');
    debugPrint('widget.isTransitioning: ${widget.isTransitioning}');
    debugPrint('widget.timeLeftMs: ${widget.timeLeftMs}');
    
    // Initial cache populate
    if (_cachedQuestion == null && widget.battle.currentQuestion != null) {
      _cachedQuestion = widget.battle.currentQuestion;
      _cachedIndex = widget.uiIndex;
    }

    final question = _cachedQuestion;
    debugPrint('_cachedQuestion: $question');
    
    if (question == null) {
      debugPrint('Returning "Get ready..." screen');
      return Center(
        child: Text(
          widget.isBn ? 'রেডি হোন...' : 'Get ready...',
          style: AppTextStyles.titleMedium(context),
        ),
      );
    }

    final qId = question['id'] as String;
    final text = question['text'] ?? '';
    
    final rawOptions = question['options'] ?? [];
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
        // Timer Area matching QuizTimerBar style
        Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 16.r,
              color: timeIsUp ? AppColors.danger : AppColors.goldLight,
            ),
            SizedBox(width: 6.w),
            Text(
              widget.isBn ? 'সময় বাকি' : 'Time Remaining',
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const Spacer(),
            Text(
              formatQuizDuration((widget.timeLeftMs / 1000).ceil()),
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: timeIsUp ? AppColors.danger : AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ScoreBar(
          value: widget.timeLeftMs / (widget.battle.secondsPerQuestion * 1000),
          height: 6,
          color: timeIsUp ? AppColors.danger : AppColors.gold,
        ),
        SizedBox(height: 16.h),
        
        // Progress Area matching QuizQuestionScreen style
        Text(
          widget.isBn 
              ? 'প্রশ্ন ${widget.uiIndex + 1} / ${widget.battle.questionCount}'
              : 'Question ${widget.uiIndex + 1} of ${widget.battle.questionCount}',
          style: AppTextStyles.bodySmall(context).copyWith(
            color: AppColors.textMuted,
          ),
        ),
        SizedBox(height: 6.h),
        ScoreBar(
          value: quizProgressValue(
            widget.uiIndex,
            widget.battle.questionCount,
          ),
          height: 6,
        ),
        SizedBox(height: 16.h),

        // Question Text
        CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isBn ? 'প্রশ্ন' : 'Question',
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
              return Consumer(
                builder: (context, ref, child) {
                  // Fetch answers for this question to show avatars when revealed
                  final answersAsync = ref.watch(battleAnswersProvider((code: widget.battleCode, questionId: qId)));
                  final allAnswers = answersAsync.value ?? [];
                  final playersWhoPickedThis = allAnswers.where((a) => a.selectedIndex == index).toList();

                  final isSelectedByMe = widget.selectedIndex == index;
                  
                  // Determine state
                  QuizOptionTileState tileState = QuizOptionTileState.idle;
                  
                  if (isRevealed && globalCorrectIndex != null) {
                    if (index == globalCorrectIndex) {
                      tileState = QuizOptionTileState.correct;
                    } else if (isSelectedByMe) {
                      tileState = QuizOptionTileState.wrong;
                    }
                  } else if (isSelectedByMe) {
                    if (widget.isCorrect == true) {
                      tileState = QuizOptionTileState.correct;
                    } else if (widget.isCorrect == false) {
                      tileState = QuizOptionTileState.wrong;
                    } else {
                      tileState = QuizOptionTileState.selected;
                    }
                  }

                  Widget? trailingWidget;
                  if (isSelectedByMe && widget.isSubmitting) {
                    trailingWidget = SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                    );
                  } else if (isRevealed && playersWhoPickedThis.isNotEmpty) {
                    trailingWidget = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: playersWhoPickedThis.map((a) {
                        return Padding(
                          padding: EdgeInsets.only(left: 4.w),
                          child: AvatarChip(
                            initial: 'P',
                            color: AppColors.ice,
                            size: 24.r,
                          ),
                        );
                      }).toList(),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: QuizOptionTile(
                      index: index,
                      label: options[index],
                      state: tileState,
                      enabled: !isRevealed && !widget.isSubmitting,
                      onTap: () => widget.onSubmit(index),
                      trailing: trailingWidget,
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
            padding: EdgeInsets.only(top: 8.h),
            child: Row(
              children: [
                const Spacer(),
                FilledButton(
                  onPressed: (!isRevealed || widget.isTransitioning || widget.isAutoAdvancing) ? null : widget.onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  ),
                  child: widget.isAutoAdvancing
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.emeraldDeep),
                        )
                      : Text(
                          widget.uiIndex >= widget.battle.questionCount - 1
                              ? (widget.isBn ? 'ব্যাটেল শেষ করুন' : 'Finish Battle')
                              : (widget.isBn ? 'পরবর্তী প্রশ্ন' : 'Next Question'),
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.emeraldDeep,
                          ),
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
