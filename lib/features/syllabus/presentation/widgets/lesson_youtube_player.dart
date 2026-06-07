import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/youtube_url_helper.dart';
import '../../../../l10n/app_localizations.dart';
import 'lesson_youtube_toolbar.dart';

class LessonYoutubePlayer extends StatefulWidget {
  const LessonYoutubePlayer({
    super.key,
    required this.videoUrl,
    this.title,
    this.captionLanguage = 'en',
  });

  final String videoUrl;
  final String? title;
  final String captionLanguage;

  @override
  State<LessonYoutubePlayer> createState() => _LessonYoutubePlayerState();
}

class _LessonYoutubePlayerState extends State<LessonYoutubePlayer> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant LessonYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.captionLanguage != widget.captionLanguage) {
      _controller?.close();
      _controller = null;
      _initController();
    }
  }

  void _initController() {
    final videoId = extractYoutubeVideoId(widget.videoUrl);
    if (videoId == null) return;
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      params: YoutubePlayerParams(
        videoStateUpdateInterval: 50,
        enableCaption: true,
        captionLanguage: widget.captionLanguage,
        interfaceLanguage: widget.captionLanguage,
        strictRelatedVideos: true,
        showVideoAnnotations: false,
        playsInline: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  YoutubePlayerTheme get _playerTheme => const YoutubePlayerTheme(
        progressBarActiveColor: AppColors.gold,
        progressBarBufferedColor: Color(0x66C9A84C),
        progressBarBackgroundColor: Color(0x33FFFFFF),
        controlsColor: AppColors.cream,
        controlsBackgroundGradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xCC0D3D2E), Colors.transparent],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;

    if (controller == null) {
      return _PlayerFrame(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: Icon(
              Icons.play_disabled_outlined,
              size: 40.r,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    final title = widget.title?.trim();

    return _PlayerFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null && title.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 10.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.emeraldMid,
                    AppColors.emeraldLight.withValues(alpha: 0.85),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.goldBorder),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.goldCard,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 18.r,
                      color: AppColors.gold,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.syllabusVideoNowPlaying,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.gold,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Theme(
            data: Theme.of(context).copyWith(
              extensions: <ThemeExtension<dynamic>>[_playerTheme],
            ),
            child: YoutubePlayer(
              controller: controller,
              aspectRatio: 16 / 9,
              keepAlive: true,
              gestureRecognizers: {
                Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
              },
              backgroundColor: AppColors.emeraldDeep,
              autoHideDuration: const Duration(seconds: 4),
              enableFullScreenOnVerticalDrag: true,
              autoFullScreen: true,
            ),
          ),
          RepaintBoundary(
            child: LessonYoutubeToolbar(
              controller: controller,
              videoUrl: widget.videoUrl,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerFrame extends StatelessWidget {
  const _PlayerFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: AppColors.goldBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.14),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        child: child,
      ),
    );
  }
}
