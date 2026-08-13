import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
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
          style: AppTextStyles.headlineMedium(context),
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
                isBn ? 'ব্যাটেল খুঁজে পাওয়া যায়নি' : 'Battle not found',
                style: AppTextStyles.bodyMedium(context),
              ),
            );
          }

          // Handle battle lifecycle state routing here
          if (battle.status == 'cancelled' || battle.status == 'expired') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go(AppRoutes.battleTopics);
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
              
              // Code Display
              CardContainer(
                color: AppColors.goldCard,
                borderColor: AppColors.goldBorder,
                child: Column(
                  children: [
                    Text(
                      isBn ? 'আপনার ব্যাটেল কোড' : 'YOUR BATTLE CODE',
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: AppColors.gold,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      battle.id.toUpperCase(),
                      style: TextStyle(
                        fontSize: 48.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8.w,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      isBn 
                          ? 'অন্যদের সাথে এই কোডটি শেয়ার করুন' 
                          : 'Share this code with others to join',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
              
              OutlinedButton.icon(
                onPressed: () {
                  final code = battle.id.toUpperCase();
                  final link = 'https://amoltracker.app/battle/join?code=$code';
                  final text = isBn 
                      ? 'আমার সাথে নলেজ ব্যাটেল খেলুন! জয়েন কোড: $code\nলিংক: $link'
                      : 'Join my Knowledge Battle! Code: $code\nLink: $link';
                  Share.share(text);
                },
                icon: Icon(Icons.share_rounded, color: AppColors.gold, size: 20.r),
                label: Text(
                  isBn ? 'ইনভাইট লিংক শেয়ার করুন' : 'Share Invite Link',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),

              SizedBox(height: 32.h),
              
              Text(
                isBn ? 'খেলোয়াড় ($playerCount/2)' : 'PLAYERS ($playerCount/2)',
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView.separated(
                  itemCount: playerCount,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
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
                    isBn ? 'ব্যাটেল শুরু হয়েছে!' : 'Battle started!',
                    style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.gold),
                  ),
                )
              else if (isHost)
                ElevatedButton(
                  onPressed: (_isStarting || !canStart) ? null : () => _startBattle(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.3),
                    foregroundColor: AppColors.emeraldDeep,
                    disabledForegroundColor: AppColors.emeraldDeep.withValues(alpha: 0.5),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: _isStarting
                      ? SizedBox(
                          height: 20.r,
                          width: 20.r,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.emeraldDeep),
                        )
                      : Text(
                          isBn ? 'ব্যাটেল শুরু করুন' : 'Start Battle',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                )
              else
                Center(
                  child: Text(
                    isBn ? 'হোস্টের শুরুর অপেক্ষায়...' : 'Waiting for host to start...',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, st) => Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium(context))),
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

    return CardContainer(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
              child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)
            ),
            error: (_, __) => AvatarChip(initial: '?', color: AppColors.textMuted, size: 40.r),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                playerAsync.when(
                  data: (user) => Text(
                    (user?.name ?? 'Player') + (isMe ? (isBn ? ' (আপনি)' : ' (You)') : ''),
                    style: AppTextStyles.titleSmall(context).copyWith(fontWeight: FontWeight.w600),
                  ),
                  loading: () => Text(isBn ? 'লোড হচ্ছে...' : 'Loading...', style: AppTextStyles.titleSmall(context)),
                  error: (_, __) => Text('Unknown Player', style: AppTextStyles.titleSmall(context)),
                ),
                if (isHost) ...[
                  SizedBox(height: 4.h),
                  Text(
                    isBn ? 'হোস্ট' : 'Host',
                    style: AppTextStyles.labelSmall(context).copyWith(color: AppColors.gold),
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
