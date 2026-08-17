import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';

class LessonAudioPlayer extends StatefulWidget {
  const LessonAudioPlayer({
    super.key,
    required this.audioUrl,
    required this.title,
  });

  final String audioUrl;
  final String title;

  @override
  State<LessonAudioPlayer> createState() => _LessonAudioPlayerState();
}

class _LessonAudioPlayerState extends State<LessonAudioPlayer> {
  final _player = AudioPlayer();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.audioUrl.trim();
    if (url.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'empty';
      });
      return;
    }
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await _player.setUrl(url);
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'load';
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return CardContainer(
        child: SizedBox(
          height: 80.h,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        ),
      );
    }

    if (_error != null) {
      return CardContainer(
        child: Text(
          l10n.syllabusAudioLoadFailed,
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.headphones_outlined, color: AppColors.goldLight, size: 22.r),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          StreamBuilder<Duration?>(
            stream: _player.durationStream,
            builder: (context, durationSnap) {
              final duration = durationSnap.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, positionSnap) {
                  final position = positionSnap.data ?? Duration.zero;
                  final maxMs = duration.inMilliseconds;
                  final value = maxMs > 0
                      ? position.inMilliseconds / maxMs
                      : 0.0;
                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.gold,
                          inactiveTrackColor: AppColors.cardBorder,
                          thumbColor: AppColors.gold,
                          overlayColor: AppColors.gold.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: value.clamp(0.0, 1.0),
                          onChanged: maxMs > 0
                              ? (v) async {
                                  try {
                                    await _player.seek(
                                      Duration(
                                        milliseconds: (v * maxMs).round(),
                                      ),
                                    );
                                  } catch (_) {}
                                }
                              : null,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10.sp,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
          SizedBox(height: 8.h),
          Center(
            child: StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snap) {
                final playing = snap.data?.playing ?? false;
                return IconButton.filled(
                  onPressed: () async {
                    try {
                      if (playing) {
                        await _player.pause();
                      } else {
                        await _player.play();
                      }
                    } catch (_) {}
                  },
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 28.r,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    minimumSize: Size(56.r, 56.r),
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
