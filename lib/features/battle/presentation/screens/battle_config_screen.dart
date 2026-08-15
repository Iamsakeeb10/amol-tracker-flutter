import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../providers/locale_provider.dart';
import '../../providers/topic_providers.dart';
import '../../providers/battle_providers.dart';

class BattleConfigScreen extends ConsumerStatefulWidget {
  final String topicId;

  const BattleConfigScreen({super.key, required this.topicId});

  @override
  ConsumerState<BattleConfigScreen> createState() => _BattleConfigScreenState();
}

class _BattleConfigScreenState extends ConsumerState<BattleConfigScreen> {
  int _questionCount = 10;
  int _timeLimitSeconds = 300; // default 5 mins
  int _maxPlayers = 2;
  bool _isCreating = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).languageCode;
    final activeTopicsAsync = ref.watch(activeTopicsProvider);

    final isBn = locale == 'bn';
    final titleText = isBn ? 'ব্যাটেল কনফিগার' : 'Configure Battle';
    final qCountText = isBn ? 'প্রশ্ন সংখ্যা' : 'Question Count';
    final timeText = isBn ? 'প্রতি প্রশ্নের সময়' : 'Time per Question';
    final playersText = isBn ? 'সর্বোচ্চ খেলোয়াড়' : 'Max Players';
    final createBtnText = isBn ? 'ব্যাটেল তৈরি করুন' : 'Create Battle';
    final loadingText = isBn ? 'লোড হচ্ছে...' : 'Loading...';
    final customText = isBn ? 'কাস্টম' : 'Custom';

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          titleText,
          style: AppTextStyles.headlineMedium(context).copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24.r),
          onPressed: () => context.pop(),
        ),
      ),
      body: activeTopicsAsync.when(
        data: (topics) {
          final topic = topics.firstWhere(
            (t) => t.id == widget.topicId,
            orElse: () => topics.first, // fallback
          );

          // Clamp question count if topic has fewer active questions
          final maxQ = topic.questionCount;
          if (_questionCount > maxQ) _questionCount = maxQ;
          if (_questionCount < 1 && maxQ > 0) _questionCount = 1;

          // Generate dynamic options for question count
          List<int> questionOptions = [];
          if (maxQ > 0) {
            final Set<int> opts = {};
            // Add standard presets that fit within maxQ
            for (int p in [5, 10, 15, 20]) {
              if (p <= maxQ) opts.add(p);
            }
            // Always include maxQ
            opts.add(maxQ);
            
            // If we have too few options (e.g., maxQ is 5 gives only [5]), add smaller ones
            if (opts.length < 3) {
              if (maxQ >= 3) opts.add(3);
              if (maxQ >= 2) opts.add(2);
              if (maxQ == 5) opts.add(4); // For maxQ=5, show [2, 3, 4, 5]
            }
            
            questionOptions = opts.toList()..sort();
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(0.w, 8.h, 0.w, 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  _ErrorBanner(message: _error!),
                  SizedBox(height: 16.h),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ConfigSection(
                          icon: Icons.quiz_rounded,
                          title: qCountText,
                          valueLabel: '$_questionCount',
                          child: _ChoiceRow(
                            options: questionOptions,
                            selectedValue: _questionCount,
                            onSelected: (val) => setState(() => _questionCount = val),
                            customLabel: customText,
                            onCustomTap: () => _showCustomCountSheet(maxQ, qCountText, customText),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _ConfigSection(
                          icon: Icons.timer_rounded,
                          title: isBn ? 'সর্বমোট সময়' : 'Total Time Limit',
                          valueLabel: '${_timeLimitSeconds ~/ 60}${isBn ? " মি" : "m"}',
                          child: _ChoiceRow(
                            options: const [60, 180, 300, 600],
                            selectedValue: _timeLimitSeconds,
                            onSelected: (val) => setState(() => _timeLimitSeconds = val),
                            labelBuilder: (val) => '${val ~/ 60}${isBn ? " মি" : "m"}',
                            customLabel: customText,
                            onCustomTap: () => _showCustomTimeSheet(isBn ? 'সর্বমোট সময় (মিনিট)' : 'Total Time Limit (Minutes)', customText),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _ConfigSection(
                          icon: Icons.group_rounded,
                          title: playersText,
                          valueLabel: '$_maxPlayers',
                          child: _ChoiceRow(
                            options: const [2, 3, 4, 5],
                            selectedValue: _maxPlayers,
                            onSelected: (val) => setState(() => _maxPlayers = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                _CreateBattleButton(
                  label: createBtnText,
                  isLoading: _isCreating,
                  enabled: _questionCount >= 1,
                  onTap: _createBattle,
                ),
              ],
            ),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.gold),
              SizedBox(height: 16.h),
              Text(
                loadingText,
                style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              'Error: $err',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: AppColors.danger),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomCountSheet(int maxQ, String title, String confirmStr) async {
    final controller = TextEditingController(text: _questionCount.toString());
    String? errorMessage;
    final isBn = ref.read(localeProvider).languageCode == 'bn';
    final subtitleStr = isBn ? '১ থেকে $maxQ এর মধ্যে একটি সংখ্যা দিন' : 'Enter a number between 1 and $maxQ';
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
                decoration: BoxDecoration(
                  color: AppColors.emeraldDeep,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl.r)),
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
                            color: AppColors.goldCard,
                            borderRadius: BorderRadius.circular(AppRadius.sm.r),
                            border: Border.all(color: AppColors.goldBorder),
                          ),
                          child: Icon(Icons.quiz_rounded, color: AppColors.gold, size: 18.r),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            title,
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
                      subtitleStr,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '1 - $maxQ',
                        hintStyle: TextStyle(
                          color: AppColors.textHint,
                          letterSpacing: 2,
                          fontWeight: FontWeight.normal,
                        ),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                          borderSide: BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                          borderSide: BorderSide(color: AppColors.danger),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
                        ),
                      ),
                      onChanged: (v) {
                         if (errorMessage != null) setModalState(() => errorMessage = null);
                      },
                    ),
                    if (errorMessage != null) ...[
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16.r),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(fontSize: 12.5.sp, color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 24.h),
                    GestureDetector(
                      onTap: () {
                        final val = int.tryParse(controller.text);
                        if (val == null || val < 1 || val > maxQ) {
                          setModalState(() {
                             errorMessage = subtitleStr; // Reuse subtitle text as error
                          });
                        } else {
                          setState(() => _questionCount = val);
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          confirmStr, 
                          style: TextStyle(
                            color: AppColors.emeraldDeep, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 15.sp,
                          )
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _showCustomTimeSheet(String title, String confirmStr) async {
    final controller = TextEditingController(text: (_timeLimitSeconds ~/ 60).toString());
    String? errorMessage;
    final isBn = ref.read(localeProvider).languageCode == 'bn';
    final subtitleStr = isBn ? '১ থেকে ৬০ মিনিটের মধ্যে একটি সংখ্যা দিন' : 'Enter a number between 1 and 60 minutes';
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
                decoration: BoxDecoration(
                  color: AppColors.emeraldDeep,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl.r)),
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
                            color: AppColors.goldCard,
                            borderRadius: BorderRadius.circular(AppRadius.sm.r),
                            border: Border.all(color: AppColors.goldBorder),
                          ),
                          child: Icon(Icons.timer_rounded, color: AppColors.gold, size: 18.r),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      subtitleStr,
                      style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.cardDark,
                        hintText: isBn ? 'যেমন: 15' : 'e.g. 15',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        errorText: errorMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                          borderSide: BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                          borderSide: BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                          borderSide: BorderSide(color: AppColors.gold),
                        ),
                      ),
                      onChanged: (val) {
                        if (errorMessage != null) {
                          setModalState(() => errorMessage = null);
                        }
                      },
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.emeraldDeep,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                        ),
                      ),
                      onPressed: () {
                        final val = int.tryParse(controller.text.trim());
                        if (val == null || val < 1 || val > 60) {
                          setModalState(() {
                            errorMessage = isBn ? 'সঠিক সময় দিন (১-৬০ মিনিট)' : 'Invalid time (1-60)';
                          });
                          return;
                        }
                        setState(() => _timeLimitSeconds = val * 60);
                        Navigator.pop(context);
                      },
                      child: Text(
                        confirmStr,
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                      ),
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

  void _createBattle() async {
    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final repo = ref.read(battleRepositoryProvider);
      final res = await repo.createBattle(
        topicId: widget.topicId,
        questionCount: _questionCount,
        timeLimitSeconds: _timeLimitSeconds,
        maxPlayers: _maxPlayers,
      );

      final code = res.code;
      if (mounted && code != null) {
        LocalStorageService.saveActiveBattleCode(code);
        context.pushReplacement(AppRoutes.battleWaitingRoomPath(code));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}

/// Config section container — icon badge + title on the left, a small gold
/// pill showing the current selection on the right, then the option row
/// below. Replaces the old generic CardContainer.
class _ConfigSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String valueLabel;
  final Widget child;

  const _ConfigSection({
    required this.icon,
    required this.title,
    required this.valueLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.goldCard,
                  borderRadius: BorderRadius.circular(AppRadius.sm.r),
                  border: Border.all(color: AppColors.goldBorder),
                ),
                child: Icon(icon, color: AppColors.gold, size: 18.r),
              ),
              SizedBox(width: 12.w),
             Expanded(
  child: Text(
    title,
    strutStyle: StrutStyle(fontSize: 15.sp, height: 1.0, forceStrutHeight: true),
    style: TextStyle(
      fontSize: 15.sp,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
  ),
),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.goldCard,
                  borderRadius: BorderRadius.circular(AppRadius.sm.r),
                  border: Border.all(color: AppColors.goldBorder),
                ),
                child: Text(
  valueLabel,
  strutStyle: StrutStyle(fontSize: 12.sp, height: 1.0, forceStrutHeight: true),
  style: TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.gold,
  ),
),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }
}

/// Custom pill option selector — replaces the default Material ChoiceChip
/// so every color comes from AppColors instead of the app theme.
class _ChoiceRow extends StatelessWidget {
  final List<int> options;
  final int selectedValue;
  final ValueChanged<int> onSelected;
  final String labelSuffix;
  final String Function(int)? labelBuilder;
  final String? customLabel;
  final VoidCallback? onCustomTap;

  const _ChoiceRow({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.labelSuffix = '',
    this.labelBuilder,
    this.customLabel,
    this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCustomValue = customLabel != null && !options.contains(selectedValue);
    
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: [
        ...options.map((opt) {
          final isSelected = selectedValue == opt;
          return GestureDetector(
            onTap: () => onSelected(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold : AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppRadius.md.r),
                border: Border.all(
                  color: isSelected ? AppColors.gold : AppColors.cardBorder,
                  width: isSelected ? 1.4 : 1,
                ),
              ),
              child: Text(
                labelBuilder != null ? labelBuilder!(opt) : '$opt$labelSuffix',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.emeraldDeep : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }),
        if (customLabel != null && onCustomTap != null)
          GestureDetector(
            onTap: onCustomTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: hasCustomValue ? AppColors.gold : AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppRadius.md.r),
                border: Border.all(
                  color: hasCustomValue ? AppColors.gold : AppColors.cardBorder,
                  width: hasCustomValue ? 1.4 : 1,
                ),
              ),
              child: Text(
                hasCustomValue ? (labelBuilder != null ? labelBuilder!(selectedValue) : '$selectedValue$labelSuffix') : customLabel!,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: hasCustomValue ? FontWeight.bold : FontWeight.normal,
                  color: hasCustomValue ? AppColors.emeraldDeep : AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Inline error banner, styled with the danger palette instead of a plain
/// colored Text.
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(AppRadius.md.r),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13.sp, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold gradient CTA button, matching the join-battle button style used on
/// the battle home screen for visual consistency.
class _CreateBattleButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _CreateBattleButton({
    required this.label,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = isLoading || !enabled;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled && !isLoading ? 0.5 : 1,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gold, AppColors.goldLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 20.r,
                    width: 20.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.emeraldDeep,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.emeraldDeep,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}