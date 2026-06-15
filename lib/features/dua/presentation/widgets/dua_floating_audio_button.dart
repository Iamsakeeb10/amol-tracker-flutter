import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/colors.dart';

/// Base URL for dua audio paths from bundled JSON (e.g. `/audio/dua/1.mp3`).
const kDuaAudioBaseUrl = 'https://islamicapi.com';

/// Visual size of the floating play button (logical dp).
const double kDuaFloatingAudioButtonSize = 60;

/// Offset from the reader bottom/right edges.
const double kDuaFloatingAudioButtonMargin = 20;

/// Extra space below the button so the last lines stay readable.
const double kDuaFloatingAudioScrollClearance = 24;

/// Bottom [SingleChildScrollView] padding — clears the FAB when audio is available.
double duaPageScrollBottomPadding({required bool hasAudio}) {
  if (!hasAudio) return 32.h;
  return kDuaFloatingAudioButtonMargin.h +
      kDuaFloatingAudioButtonSize.r +
      kDuaFloatingAudioScrollClearance.h;
}

/// Floating play/pause button for dua recitation audio.
class DuaFloatingAudioButton extends StatefulWidget {
  const DuaFloatingAudioButton({
    super.key,
    required this.audioUrl,
  });

  final String audioUrl;

  @override
  State<DuaFloatingAudioButton> createState() => _DuaFloatingAudioButtonState();
}

class _DuaFloatingAudioButtonState extends State<DuaFloatingAudioButton> {
  final AudioPlayer _player = AudioPlayer();

  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  @override
  void didUpdateWidget(covariant DuaFloatingAudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _resetForNewAudio();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _resetForNewAudio() async {
    try {
      await _player.stop();
      await _player.seek(Duration.zero);
    } catch (_) {
      // Ignore stop errors when switching duas.
    }
    if (!mounted) return;
    setState(() {
      _isLoaded = false;
      _hasError = false;
    });
  }

  Future<void> _togglePlayPause() async {
    if (_hasError) {
      setState(() => _hasError = false);
      await _resetForNewAudio();
    }

    if (_player.playerState.playing) {
      await _player.pause();
      return;
    }

    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }

    try {
      if (!_isLoaded) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        await _player.setUrl(widget.audioUrl);
        if (!mounted) return;
        setState(() => _isLoaded = true);
      }
      await _player.play();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoaded = false;
      });
    }
  }

  Widget _buildIcon(PlayerState? playerState) {
    if (_hasError) {
      return Icon(Icons.refresh_rounded, color: Colors.white, size: 28.r);
    }

    final processingState =
        playerState?.processingState ?? ProcessingState.idle;
    final isBuffering = processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering;

    if (isBuffering) {
      return SizedBox(
        width: 24.r,
        height: 24.r,
        child: CircularProgressIndicator(
          strokeWidth: 2.5.r,
          color: Colors.white,
        ),
      );
    }

    final playing = playerState?.playing ?? false;
    return Icon(
      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
      color: Colors.white,
      size: 32.r,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        return Material(
          elevation: 6,
          shadowColor: AppColors.emeraldDeep.withValues(alpha: 0.4),
          shape: const CircleBorder(),
          color: AppColors.emeraldMid,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _togglePlayPause,
            child: SizedBox(
              width: kDuaFloatingAudioButtonSize.r,
              height: kDuaFloatingAudioButtonSize.r,
              child: Center(child: _buildIcon(snapshot.data)),
            ),
          ),
        );
      },
    );
  }
}
