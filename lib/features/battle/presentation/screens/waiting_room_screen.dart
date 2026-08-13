import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/router/routes.dart';
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
  String? _error;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).languageCode;
    final isBn = locale == 'bn';
    final battleAsync = ref.watch(battleStreamProvider(widget.battleCode));
    final currentUser = ref.watch(currentUserProvider).asData?.value;

    return AppScaffold(
      // Override back button to handle leaveBattle
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
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24.r),
          onPressed: () => _handleLeave(context),
        ),
      ),
      body: battleAsync.when(
        data: (battle) {
          if (battle == null) {
            return Center(
              child: Text(
                isBn ? 'ব্যাটেল খুঁজে পাওয়া যায়নি' : 'Battle not found',
                style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              ),
            );
          }

          // Handle battle lifecycle state routing here
          if (battle.status == 'cancelled' || battle.status == 'expired') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
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
          final canStart = isHost && playerCount >= 2;

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
                    final link = 'https://amoltracker.app/battle/join?code=$code';
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
                  valueLabel: '$playerCount/2',
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: ListView.separated(
                    itemCount: playerCount,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final uid = battle.playerUids[index];
                      return _PlayerTile(
                        uid: uid,
                        isHost: uid == battle.hostUid,
                        isMe: uid == currentUser?.uid,
                        locale: locale,
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
                else if (isHost)
                  _StartBattleButton(
                    label: isBn ? 'ব্যাটেল শুরু করুন' : 'Start Battle',
                    isLoading: _isStarting,
                    enabled: canStart,
                    onTap: _startBattle,
                  )
                else
                  Center(
                    child: Text(
                      isBn ? 'হোস্টের শুরুর অপেক্ষায়...' : 'Waiting for host to start...',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, st) => Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              'Error: $e',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: AppColors.danger),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLeave(BuildContext context) async {
    try {
      final repo = ref.read(battleRepositoryProvider);
      await repo.leaveBattle(code: widget.battleCode);
    } catch (e) {
      debugPrint('Failed to leave battle: $e');
    }
    if (mounted) context.pop();
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
      if (mounted) setState(() => _error = e.toString());
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
      padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: AppSpacing.lg.r),
      decoration: BoxDecoration(
        color: AppColors.goldCard,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: AppColors.goldBorder, width: 1.4),
      ),
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
  final bool isHost;
  final bool isMe;
  final String locale;

  const _PlayerTile({
    required this.uid,
    required this.isHost,
    required this.isMe,
    required this.locale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(battlePlayerProvider(uid));
    final isBn = locale == 'bn';

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
          playerAsync.when(
            data: (user) {
              final name = user?.name ?? 'Player';
              final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
              return AvatarChip(
                initial: initial,
                color: AppColors.ice,
                size: 40.r,
              );
            },
            loading: () => SizedBox(
              width: 40.r,
              height: 40.r,
              child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
            ),
            error: (_, __) => AvatarChip(initial: '?', color: AppColors.textMuted, size: 40.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                playerAsync.when(
                  data: (user) => Text(
                    (user?.name ?? 'Player') + (isMe ? (isBn ? ' (আপনি)' : ' (You)') : ''),
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  loading: () => Text(
                    isBn ? 'লোড হচ্ছে...' : 'Loading...',
                    style: TextStyle(fontSize: 14.5.sp, color: AppColors.textSecondary),
                  ),
                  error: (_, __) => Text(
                    'Unknown Player',
                    style: TextStyle(fontSize: 14.5.sp, color: AppColors.textSecondary),
                  ),
                ),
                if (isHost) ...[
                  SizedBox(height: 4.h),
                  Text(
                    isBn ? 'হোস্ট' : 'Host',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ],
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

/// Gold gradient CTA — matches the Create Battle / Join Battle buttons used
/// elsewhere in the battle flow.
class _StartBattleButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _StartBattleButton({
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