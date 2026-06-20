import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/quran_reading_prefs_provider.dart';
import 'mushaf_jump_sheet.dart';
import 'translation_panel.dart';

class MushafOverlayControls extends ConsumerStatefulWidget {
  const MushafOverlayControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.currentJuz,
    required this.visible,
    required this.onToggleVisibility,
    required this.onJumpToPage,
    required this.onInteraction,
  });

  final int currentPage;
  final int totalPages;
  final int currentJuz;
  final bool visible;
  final VoidCallback onToggleVisibility;
  final ValueChanged<int> onJumpToPage;
  final VoidCallback onInteraction;

  @override
  ConsumerState<MushafOverlayControls> createState() =>
      _MushafOverlayControlsState();
}

class _MushafOverlayControlsState extends ConsumerState<MushafOverlayControls> {
  Timer? _autoHideTimer;

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MushafOverlayControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _scheduleAutoHide();
    }
    if (!widget.visible) {
      _autoHideTimer?.cancel();
    }
  }

  void _scheduleAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.visible) {
        widget.onToggleVisibility();
      }
    });
  }

  void _handleInteraction(VoidCallback action) {
    widget.onInteraction();
    _scheduleAutoHide();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(quranReadingPrefsProvider);
    final notifier = ref.read(quranReadingPrefsProvider.notifier);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onToggleVisibility,
          ),
        ),
        IgnorePointer(
          ignoring: !widget.visible,
          child: AnimatedOpacity(
            opacity: widget.visible ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: Column(
              children: [
                _OverlayBar(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.quranJuz(widget.currentJuz)} · ${l10n.quranPageOf(widget.currentPage, widget.totalPages)}',
                          style: AppTextStyles.bodyLarge(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.quranTranslation,
                        onPressed: () => _handleInteraction(
                          () => showTranslationPanel(context),
                        ),
                        icon: Icon(Icons.translate_outlined, size: 22.r),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _OverlayBar(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.gold,
                          inactiveTrackColor:
                              AppColors.gold.withValues(alpha: 0.2),
                          thumbColor: AppColors.gold,
                          overlayColor: AppColors.gold.withValues(alpha: 0.15),
                        ),
                        child: Slider(
                          value: widget.currentPage.toDouble(),
                          min: 1,
                          max: widget.totalPages.toDouble(),
                          divisions: widget.totalPages - 1,
                          label: '${widget.currentPage}',
                          onChanged: (value) => _handleInteraction(
                            () => widget.onJumpToPage(value.round()),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleInteraction(
                                () => showMushafJumpSheet(
                                  context,
                                  currentPage: widget.currentPage,
                                  totalPages: widget.totalPages,
                                  onJumpToPage: widget.onJumpToPage,
                                ),
                              ),
                              icon: Icon(Icons.bookmark_border_rounded, size: 18.r),
                              label: Text(l10n.quranJumpToPage),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleInteraction(
                                () => showMushafJumpSheet(
                                  context,
                                  currentPage: widget.currentPage,
                                  totalPages: widget.totalPages,
                                  onJumpToPage: widget.onJumpToPage,
                                  initialTab: 1,
                                ),
                              ),
                              icon: Icon(Icons.list_rounded, size: 18.r),
                              label: Text(l10n.quranJumpToSurah),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          IconButton(
                            tooltip: l10n.duaReaderTextSizeDecrease,
                            onPressed: prefs.arabicFontScale > 0.8
                                ? () => _handleInteraction(
                                      () => notifier.decreaseFontScale(),
                                    )
                                : null,
                            icon: Icon(Icons.remove_rounded, size: 22.r),
                          ),
                          Text(
                            '${(prefs.arabicFontScale * 100).round()}%',
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.duaReaderTextSizeIncrease,
                            onPressed: prefs.arabicFontScale < 1.6
                                ? () => _handleInteraction(
                                      () => notifier.increaseFontScale(),
                                    )
                                : null,
                            icon: Icon(Icons.add_rounded, size: 22.r),
                          ),
                          const Spacer(),
                          Text(
                            l10n.quranTranslation,
                            style: AppTextStyles.bodySmall(context),
                          ),
                          Switch.adaptive(
                            value: prefs.showTranslation,
                            activeTrackColor: AppColors.gold.withValues(alpha: 0.45),
                            activeThumbColor: AppColors.gold,
                            onChanged: (value) => _handleInteraction(
                              () => notifier.setShowTranslation(value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OverlayBar extends StatelessWidget {
  const _OverlayBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.emeraldDeep.withValues(alpha: 0.92),
            AppColors.emeraldDeep.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: child,
      ),
    );
  }
}
