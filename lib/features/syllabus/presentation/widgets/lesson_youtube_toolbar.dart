import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/utils/external_url_helper.dart';
import '../../../../core/utils/youtube_url_helper.dart';
import '../../../../l10n/app_localizations.dart';

class LessonYoutubeToolbar extends StatefulWidget {
  const LessonYoutubeToolbar({
    super.key,
    required this.controller,
    required this.videoUrl,
  });

  final YoutubePlayerController controller;
  final String videoUrl;

  @override
  State<LessonYoutubeToolbar> createState() => _LessonYoutubeToolbarState();
}

class _LessonYoutubeToolbarState extends State<LessonYoutubeToolbar> {
  bool _muted = false;
  Duration _position = Duration.zero;
  StreamSubscription<YoutubeVideoState>? _positionSub;

  @override
  void initState() {
    super.initState();
    _positionSub = widget.controller.videoStateStream.listen((state) {
      _position = state.position;
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _seekRelative(int deltaSeconds) async {
    final target = (_position.inSeconds + deltaSeconds)
        .clamp(0, 86400)
        .toDouble();
    await widget.controller.seekTo(seconds: target, allowSeekAhead: true);
    await widget.controller.playVideo();
  }

  Future<void> _restart() async {
    await widget.controller.seekTo(seconds: 0, allowSeekAhead: true);
    await widget.controller.playVideo();
  }

  Future<void> _toggleMute() async {
    final muted = await widget.controller.isMuted;
    if (muted) {
      await widget.controller.unMute();
    } else {
      await widget.controller.mute();
    }
    if (!mounted) return;
    setState(() => _muted = !muted);
  }

  Future<void> _openInYoutube() async {
    final videoId = extractYoutubeVideoId(widget.videoUrl);
    if (videoId == null) return;
    await launchExternalUrl(youtubeWatchUrl(videoId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.emeraldMid.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppColors.goldBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolbarAction(
            icon: Icons.replay_10_rounded,
            label: l10n.syllabusVideoRewind,
            onTap: () => _seekRelative(-10),
          ),
          _ToolbarAction(
            icon: Icons.forward_10_rounded,
            label: l10n.syllabusVideoForward,
            onTap: () => _seekRelative(10),
          ),
          _ToolbarAction(
            icon: Icons.restart_alt_rounded,
            label: l10n.syllabusVideoRestart,
            onTap: _restart,
          ),
          _ToolbarAction(
            icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            label: _muted ? l10n.syllabusVideoUnmute : l10n.syllabusVideoMute,
            onTap: _toggleMute,
          ),
          _ToolbarAction(
            icon: Icons.open_in_new_rounded,
            label: l10n.syllabusVideoOpenYoutube,
            onTap: _openInYoutube,
          ),
        ],
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: AppColors.goldCard,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(10.r),
            child: Icon(icon, size: 20.r, color: AppColors.goldLight),
          ),
        ),
      ),
    );
  }
}
