import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
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
  int _secondsPerQuestion = 15;
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
    final timeText = isBn ? 'প্রতি প্রশ্নের সময়' : 'Time per Question';
    final playersText = isBn ? 'সর্বোচ্চ খেলোয়াড়' : 'Max Players';
    final createBtnText = isBn ? 'ব্যাটেল তৈরি করুন' : 'Create Battle';
    final loadingText = isBn ? 'লোড হচ্ছে...' : 'Loading...';

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          titleText,
          style: AppTextStyles.headlineMedium(context),
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Text(
                  _error!,
                  style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
              ],
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildConfigSection(
                        title: qCountText,
                        child: _buildChoiceChips(
                          options: [5, 10, 15, 20].where((q) => q <= maxQ).toList(),
                          selectedValue: _questionCount,
                          onSelected: (val) => setState(() => _questionCount = val),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _buildConfigSection(
                        title: timeText,
                        child: _buildChoiceChips(
                          options: [10, 15, 20, 30],
                          selectedValue: _secondsPerQuestion,
                          onSelected: (val) => setState(() => _secondsPerQuestion = val),
                          labelSuffix: 's',
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _buildConfigSection(
                        title: playersText,
                        child: _buildChoiceChips(
                          options: [2, 3, 4, 5],
                          selectedValue: _maxPlayers,
                          onSelected: (val) => setState(() => _maxPlayers = val),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: (_isCreating || _questionCount < 1) ? null : () => _createBattle(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: _isCreating 
                    ? SizedBox(
                        height: 20.r,
                        width: 20.r,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.emeraldDeep),
                      )
                    : Text(
                        createBtnText,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.gold),
              SizedBox(height: 16.h),
              Text(loadingText, style: AppTextStyles.bodyMedium(context)),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: AppTextStyles.bodyMedium(context)),
        ),
      ),
    );
  }

  Widget _buildConfigSection({required String title, required Widget child}) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium(context).copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildChoiceChips({
    required List<int> options,
    required int selectedValue,
    required ValueChanged<int> onSelected,
    String labelSuffix = '',
  }) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: options.map((opt) {
        final isSelected = selectedValue == opt;
        return ChoiceChip(
          label: Text('$opt$labelSuffix'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onSelected(opt);
          },
          selectedColor: AppColors.gold,
          backgroundColor: AppColors.emeraldLight.withValues(alpha: 0.3),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.emeraldDeep : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
            side: BorderSide(
              color: isSelected ? AppColors.gold : AppColors.emeraldLight,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _createBattle() async {
    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final repo = ref.read(battleRepositoryProvider);
      final res = await repo.createBattle(
        topicId: widget.topicId,
        questionCount: _questionCount,
        secondsPerQuestion: _secondsPerQuestion,
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
