import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../providers/battle_providers.dart';

class WaitingRoomScreen extends ConsumerStatefulWidget {
  final String battleCode;

  const WaitingRoomScreen({super.key, required this.battleCode});

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  bool _isStarting = false;
  bool _isLeaving = false;
  bool _isTogglingReady = false;
  String? _error;
  
  Timer? _countdownTimer;
  int _countdown = 10;
  bool _timerActive = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).languageCode;
    final isBn = locale == 'bn';
    final battleAsync = ref.watch(battleStreamProvider(widget.battleCode));
    final currentUser = ref.watch(currentUserProvider).asData?.value;

    ref.listen(battleStreamProvider(widget.battleCode), (previous, next) {
      final battle = next.asData?.value;
      if (battle == null) {
        _cancelTimer();
        return;
      }
      
      if (battle.status == 'cancelled') {
        _cancelTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isBn ? 'ব্যাটেলটি হোস্ট বাতিল করেছেন!' : 'Battle was cancelled by the host!'),
              backgroundColor: AppColors.danger,
            ),
          );
          LocalStorageService.clearActiveBattleCode();
          context.go(AppRoutes.home);
        }
        return;
      }

      if (battle.status != 'waiting') {
        _cancelTimer();
        return;
      }

      final pCount = battle.playerUids.length;
      final readyCount = battle.readyUids?.length ?? 0;
      final isAllReady = pCount >= 2 && readyCount == pCount;

      if (isAllReady && !_timerActive && _countdown > 0) {
        _startTimer(battle.hostUid == currentUser?.uid);
      } else if (!isAllReady && (_timerActive || _countdown == 0)) {
        _cancelTimer();
      }
    });

    final isHost = battleAsync.asData?.value?.hostUid == currentUser?.uid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showExitDialog(isHost, isBn);
      },
      child: AppScaffold(
        // We handle back via PopScope above
        handleExitBack: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            isBn ? 'অপেক্ষমাণ কক্ষ' : 'Waiting Room',
            style: AppTextStyles.headlineMedium(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 24.r),
            onPressed: () => _showExitDialog(isHost, isBn),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: IconButton(
                onPressed: () => _showExitDialog(isHost, isBn),
                icon: Icon(Icons.exit_to_app_rounded, color: AppColors.danger, size: 26.r),
              ),
            ),
          ],
        ),
      body: battleAsync.when(
        data: (battle) {
          if (battle == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              LocalStorageService.clearActiveBattleCode();
              if (mounted) context.go(AppRoutes.home);
            });
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }

          // Handle battle lifecycle state routing here
          if (battle.status == 'cancelled' || battle.status == 'expired') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              LocalStorageService.clearActiveBattleCode();
              if (mounted) context.go(AppRoutes.battleHome);
            });
            return const SizedBox.shrink();
          }

          if (battle.status == 'active') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.pushReplacement(AppRoutes.battleQuizPath(widget.battleCode));
              }
            });
            // Show a tiny transition while navigating
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }

          final isHost = currentUser?.uid == battle.hostUid;
          final playerCount = battle.playerUids.length;
          final readyCount = battle.readyUids?.length ?? 0;
          final isAllReady = playerCount >= 2 && readyCount == playerCount;

          return Padding(
            padding: EdgeInsets.fromLTRB(0.w, 8.h, 0.w, 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  _ErrorBanner(message: _error!),
                  SizedBox(height: 16.h),
                ],

                // Battle code display
                _BattleCodeCard(
                  code: battle.id.toUpperCase(),
                  isBn: isBn,
                ),

                SizedBox(height: 14.h),

                _ShareInviteButton(
                  isBn: isBn,
                  onTap: () {
                    final code = battle.id.toUpperCase();
                    final link = 'https://amol-tracker.web.app/battle/join?code=$code';
                    final text = isBn
                        ? 'আমার সাথে নলেজ ব্যাটেল খেলুন! জয়েন কোড: $code\nলিংক: $link'
                        : 'Join my Knowledge Battle! Code: $code\nLink: $link';
                    Share.share(text);
                  },
                ),

                SizedBox(height: 28.h),

                _SectionHeader(
                  icon: Icons.groups_rounded,
                  title: isBn ? 'খেলোয়াড়' : 'Players',
                  valueLabel: '$playerCount/${battle.maxPlayers ?? 2}',
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: ListView.separated(
                    itemCount: playerCount,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final uid = battle.playerUids[index];
                      final playerObj = battle.players?[uid];
                      final name = (playerObj is Map ? playerObj['name'] as String? : null) ?? 'Player ${index + 1}';
                      return _PlayerTile(
                        uid: uid,
                        name: name,
                        isHost: uid == battle.hostUid,
                        isMe: uid == currentUser?.uid,
                        locale: locale,
                        isReady: battle.readyUids?.contains(uid) ?? false,
                        isLoadingReady: _isTogglingReady,
                        onToggleReady: uid == currentUser?.uid 
                            ? () => _toggleReady(battle.readyUids?.contains(uid) ?? false)
                            : null,
                      );
                    },
                  ),
                ),

                // Action Area
                SizedBox(height: 16.h),
                if (battle.status == 'active')
                  Center(
                    child: Text(
                      isBn ? 'ব্যাটেল শুরু হয়েছে!' : 'Battle started!',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  )
                else if (_timerActive)
                  _CountdownDisplay(countdown: _countdown, isBn: isBn)
                else if (isAllReady && _countdown == 0)
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 28.r,
                          height: 28.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.gold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          isBn ? 'ব্যাটেল প্রস্তুত করা হচ্ছে...' : 'Preparing battle...',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, st) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            LocalStorageService.clearActiveBattleCode();
            if (mounted) context.go(AppRoutes.home);
          });
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        },
      ),
    ));
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    if (mounted && (_timerActive || _countdown == 0)) {
      setState(() {
        _timerActive = false;
        _countdown = 10;
      });
    }
  }

  void _startTimer(bool isHost) {
    setState(() {
      _countdown = 10;
      _timerActive = true;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _countdown = 0;
          timer.cancel();
          _timerActive = false;
          if (isHost && mounted) {
            _startBattle();
          }
        }
      });
    });
  }

  Future<void> _toggleReady(bool currentlyReady) async {
    setState(() {
      _isTogglingReady = true;
      _error = null;
    });
    try {
      final repo = ref.read(battleRepositoryProvider);
      await repo.toggleReady(code: widget.battleCode, isReady: !currentlyReady);
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('409') || errorStr.contains('already started') || errorStr.contains('aborted')) {
        debugPrint('toggleReady 409/Aborted caught and suppressed: $e');
      } else {
        if (mounted) setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isTogglingReady = false);
    }
  }

  void _showExitDialog(bool isHost, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.emeraldDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(
          isBn ? (isHost ? 'ব্যাটেল বাতিল করবেন?' : 'ব্যাটেল ত্যাগ করবেন?') : (isHost ? 'Cancel Battle?' : 'Leave Battle?'),
          style: AppTextStyles.titleLarge(context),
        ),
        content: Text(
          isBn 
              ? (isHost ? 'আপনি বের হয়ে গেলে ব্যাটেলটি বাতিল হয়ে যাবে।' : 'আপনি কি নিশ্চিত যে আপনি ব্যাটেলটি ত্যাগ করতে চান?') 
              : (isHost ? 'If you leave, the battle will be cancelled for everyone.' : 'Are you sure you want to leave this battle?'),
          style: AppTextStyles.bodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isBn ? 'না' : 'No', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.of(ctx).pop();
              _leaveBattle(context);
            },
            child: Text(isBn ? 'হ্যাঁ' : 'Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _leaveBattle(BuildContext context) {
    if (_isLeaving) return;
    setState(() => _isLeaving = true);

    try {
      final repo = ref.read(battleRepositoryProvider);
      repo.leaveBattle(code: widget.battleCode).catchError((e) {
        debugPrint('Failed to leave battle (background): $e');
      });
      LocalStorageService.clearActiveBattleCode();
    } catch (e) {
      debugPrint('Failed to leave battle: $e');
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      }
    });
  }

  Future<void> _startBattle() async {
    setState(() {
      _isStarting = true;
      _error = null;
    });

    try {
      final repo = ref.read(battleRepositoryProvider);
      await repo.startBattle(code: widget.battleCode);
      // We don't navigate immediately here; we let the stream listener handle it
      // when it sees status == 'active'.
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('409') || errorStr.contains('already started') || errorStr.contains('aborted')) {
        debugPrint('startBattle 409/Aborted caught and suppressed: $e');
        // Battle likely already started by another request or transaction abort but will recover via stream
      } else {
        if (mounted) setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }
}

/// Battle code hero card — gold-tinted, matches the accent styling used for
/// primary elements on the home/config screens.
class _BattleCodeCard extends StatelessWidget {
  final String code;
  final bool isBn;

  const _BattleCodeCard({required this.code, required this.isBn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.goldCard,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: AppColors.goldBorder, width: 1.4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: AppSpacing.lg.r),
            child: Column(
              children: [
                Text(
                  isBn ? 'আপনার ব্যাটেল কোড' : 'YOUR BATTLE CODE',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: AppColors.gold,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 42.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8.w,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  isBn ? 'অন্যদের সাথে এই কোডটি শেয়ার করুন' : 'Share this code with others to join',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4.h,
            right: 4.w,
            child: IconButton(
              icon: Icon(Icons.copy_rounded, color: AppColors.gold, size: 20.r),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isBn ? 'কোড কপি করা হয়েছে!' : 'Code copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.emeraldDeep,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Outlined share button — matches the app's flat, bordered secondary-action
/// style instead of the default OutlinedButton theme.
class _ShareInviteButton extends StatelessWidget {
  final bool isBn;
  final VoidCallback onTap;

  const _ShareInviteButton({required this.isBn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppRadius.md.r),
          border: Border.all(color: AppColors.goldBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share_rounded, color: AppColors.gold, size: 18.r),
            SizedBox(width: 8.w),
            Text(
              isBn ? 'ইনভাইট লিংক শেয়ার করুন' : 'Share Invite Link',
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon badge + title + trailing count pill — same header language used on
/// the config screen, reused here above the player list.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String valueLabel;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(7.r),
          decoration: BoxDecoration(
            color: AppColors.goldCard,
            borderRadius: BorderRadius.circular(AppRadius.sm.r),
            border: Border.all(color: AppColors.goldBorder),
          ),
          child: Icon(icon, color: AppColors.gold, size: 16.r),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.goldCard,
            borderRadius: BorderRadius.circular(AppRadius.sm.r),
            border: Border.all(color: AppColors.goldBorder),
          ),
          child: Text(
            valueLabel,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Player row — custom bordered container built around AvatarChip, replacing
/// CardContainer.
class _PlayerTile extends ConsumerWidget {
  final String uid;
  final String name;
  final bool isHost;
  final bool isMe;
  final String locale;
  final bool isReady;
  final bool isLoadingReady;
  final VoidCallback? onToggleReady;

  const _PlayerTile({
    required this.uid,
    required this.name,
    required this.isHost,
    required this.isMe,
    required this.locale,
    required this.isReady,
    this.isLoadingReady = false,
    this.onToggleReady,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBn = locale == 'bn';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(
          color: isMe ? AppColors.goldBorder : AppColors.cardBorder,
          width: isMe ? 1.3 : 1,
        ),
      ),
      child: Row(
        children: [
          AvatarChip(
            initial: initial,
            color: isHost ? AppColors.emeraldMid : AppColors.ice,
            size: 40.r,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name + (isMe ? (isBn ? ' (আপনি)' : ' (You)') : ''),
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    if (isHost) ...[
                      Text(
                        isBn ? 'হোস্ট' : 'Host',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Icon(
                      isReady ? Icons.check_circle_rounded : Icons.pending_rounded,
                      color: isReady ? AppColors.success : AppColors.textMuted,
                      size: 14.r,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      isReady ? (isBn ? 'রেডি' : 'Ready') : (isBn ? 'অপেক্ষমাণ...' : 'Not Ready'),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isReady ? AppColors.success : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isMe && onToggleReady != null)
            GestureDetector(
              onTap: isLoadingReady ? null : onToggleReady,
              child: Opacity(
                opacity: isLoadingReady ? 0.5 : 1,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isReady ? AppColors.danger : AppColors.gold,
                    borderRadius: BorderRadius.circular(20.r),
                    border: isReady ? Border.all(color: AppColors.danger.withValues(alpha: 0.3)) : null,
                  ),
                  child: isLoadingReady
                      ? SizedBox(
                          width: 14.r,
                          height: 14.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isReady ? AppColors.textPrimary : AppColors.emeraldDeep,
                          ),
                        )
                      : Text(
                          isReady ? (isBn ? 'রেডি নই' : 'Unready') : (isBn ? 'রেডি' : 'Ready'),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: isReady ? AppColors.textPrimary : AppColors.emeraldDeep,
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

/// Inline error banner — same danger-palette treatment used on the config
/// screen, for a consistent error state across the battle flow.
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

class _CountdownDisplay extends StatelessWidget {
  final int countdown;
  final bool isBn;

  const _CountdownDisplay({required this.countdown, required this.isBn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.emeraldMid.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md.r),
        border: Border.all(color: AppColors.goldBorder),
      ),
      child: Column(
        children: [
          Text(
            isBn ? 'ব্যাটেল শুরু হবে...' : 'Battle starts in...',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '$countdown',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingRoomExitDialog extends StatelessWidget {
  final bool isBn;
  const _WaitingRoomExitDialog({required this.isBn});

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
              isBn ? 'রুম থেকে বের হতে চান?' : 'Leave Waiting Room?',
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
                  ? 'বের হয়ে গেলে আপনি এই ব্যাটেলে আর অংশ নিতে পারবেন না।'
                  : 'If you leave, you will forfeit your spot in this battle.',
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
