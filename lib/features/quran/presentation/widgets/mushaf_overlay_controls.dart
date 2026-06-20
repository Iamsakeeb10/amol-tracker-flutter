import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../constants/mushaf_theme.dart';
import '../../providers/quran_reading_prefs_provider.dart';
import '../../utils/quran_tap_targets.dart';
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                Column(
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
                            tooltip: l10n.settings,
                            style: QuranTapTargets.iconButtonStyle(),
                            onPressed: () => _handleInteraction(
                              () => showTranslationPanel(context),
                            ),
                            icon: Icon(Icons.settings_outlined, size: 22.r),
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
                          Icon(
                            Icons.palette_outlined,
                            size: 18.r,
                            color: AppColors.gold.withValues(alpha: 0.85),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            l10n.quranPageTheme,
                            style: AppTextStyles.bodySmall(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i < MushafTheme.paperThemes.length; i++)
                            _PaperThemeSwatch(
                              theme: MushafTheme.paperThemes[i],
                              selected: prefs.mushafBgIndex == i,
                              onTap: () => _handleInteraction(
                                () => notifier.setMushafBgIndex(i),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          IconButton(
                            tooltip: l10n.duaReaderTextSizeDecrease,
                            style: QuranTapTargets.iconButtonStyle(),
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
                            style: QuranTapTargets.iconButtonStyle(),
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
        color: AppColors.emeraldDeep,
        border: Border(
          top: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.25),
            width: 1,
          ),
          bottom: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: child,
      ),
    );
  }
}

class _PaperThemeSwatch extends StatelessWidget {
  const _PaperThemeSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final MushafPaperTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: QuranTapTargets.minSize.r,
          height: QuranTapTargets.minSize.r,
          child: Center(
            child: Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: theme.paper,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.gold : theme.paperBorder,
                  width: selected ? 2.5.r : 1.r,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
