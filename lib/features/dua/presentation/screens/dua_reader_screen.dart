import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/bengali_numeral_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../models/dua_models.dart';
import '../../providers/dua_provider.dart';
import '../../providers/dua_reader_settings_provider.dart';
import '../widgets/dua_floating_audio_button.dart';
import '../widgets/dua_page.dart';
import '../widgets/dua_reader_font_control.dart';

/// Swipeable dua reader — reusable from favorites, categories, or quick nav.
class DuaReaderScreen extends ConsumerStatefulWidget {
  const DuaReaderScreen({
    super.key,
    required this.duaIds,
    this.initialIndex = 0,
  });

  final List<int> duaIds;
  final int initialIndex;

  @override
  ConsumerState<DuaReaderScreen> createState() => _DuaReaderScreenState();
}

class _DuaReaderScreenState extends ConsumerState<DuaReaderScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _focusMode = false;

  double get _actionIconSize => 24.r;

  ButtonStyle get _actionIconStyle => IconButton.styleFrom(
        padding: EdgeInsets.all(10.r),
        minimumSize: Size(44.r, 44.r),
        tapTargetSize: MaterialTapTargetSize.padded,
      );

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.duaIds.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(DuaModel dua) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(duaFavoritesProvider.notifier);
    final wasFavorite = notifier.isFavorite(dua.duaId);
    await notifier.toggle(dua.duaId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasFavorite ? l10n.duaFavRemoved : l10n.duaFavAdded),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _copyDua(DuaModel dua) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: dua.shareText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.duaCopied),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareDua(DuaModel dua) async {
    await SharePlus.instance.share(
      ShareParams(text: dua.shareText(), subject: dua.title),
    );
  }

  void _goToPrevious() {
    if (_currentIndex <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _goToNext(int total) {
    if (_currentIndex >= total - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _toggleFocusMode() {
    setState(() => _focusMode = !_focusMode);
  }

  String _pageCounterText(BuildContext context, int current, int total) {
    final l10n = AppLocalizations.of(context)!;
    if (Localizations.localeOf(context).languageCode == 'bn') {
      return '${toBengaliNumeral(current)} / ${toBengaliNumeral(total)}';
    }
    return l10n.duaPageCounter(current, total);
  }

  Future<void> _handleMoreMenuAction(
    String action,
    DuaModel dua,
    List<DuaModel> duas,
  ) async {
    final settingsNotifier = ref.read(duaReaderSettingsProvider.notifier);
    final settings = ref.read(duaReaderSettingsProvider);

    switch (action) {
      case 'prev':
        _goToPrevious();
      case 'next':
        _goToNext(duas.length);
      case 'focus':
        _toggleFocusMode();
      case 'intro':
        await settingsNotifier.setShowIntroduction(!settings.showIntroduction);
      case 'translit':
        await settingsNotifier.setShowTransliteration(
          !settings.showTransliteration,
        );
      case 'translation':
        await settingsNotifier.setShowTranslation(!settings.showTranslation);
      case 'reference':
        await settingsNotifier.setShowReference(!settings.showReference);
    }
  }

  List<PopupMenuEntry<String>> _buildMoreMenuItems(
    AppLocalizations l10n,
    List<DuaModel> duas,
  ) {
    final settings = ref.read(duaReaderSettingsProvider);
    final hasMultiple = duas.length > 1;
    final atStart = _currentIndex <= 0;
    final atEnd = _currentIndex >= duas.length - 1;

    return [
      if (hasMultiple) ...[
        PopupMenuItem<String>(
          value: 'prev',
          enabled: !atStart,
          child: _MoreMenuRow(
            icon: Icons.chevron_left_rounded,
            label: l10n.duaReaderPrevious,
          ),
        ),
        PopupMenuItem<String>(
          value: 'next',
          enabled: !atEnd,
          child: _MoreMenuRow(
            icon: Icons.chevron_right_rounded,
            label: l10n.duaReaderNext,
          ),
        ),
        const PopupMenuDivider(),
      ],
      PopupMenuItem<String>(
        value: 'focus',
        child: _MoreMenuRow(
          icon: _focusMode
              ? Icons.fullscreen_exit_rounded
              : Icons.fullscreen_rounded,
          label: _focusMode
              ? l10n.duaReaderFocusModeExit
              : l10n.duaReaderFocusMode,
        ),
      ),
      const PopupMenuDivider(),
      CheckedPopupMenuItem<String>(
        value: 'intro',
        checked: settings.showIntroduction,
        child: _MenuLabel(text: l10n.duaReaderShowIntroduction),
      ),
      CheckedPopupMenuItem<String>(
        value: 'translit',
        checked: settings.showTransliteration,
        child: _MenuLabel(text: l10n.duaReaderShowTransliteration),
      ),
      CheckedPopupMenuItem<String>(
        value: 'translation',
        checked: settings.showTranslation,
        child: _MenuLabel(text: l10n.duaReaderShowTranslation),
      ),
      CheckedPopupMenuItem<String>(
        value: 'reference',
        checked: settings.showReference,
        child: _MenuLabel(text: l10n.duaReaderShowReference),
      ),
    ];
  }

  List<Widget>? _buildActions(
    AppLocalizations l10n,
    List<DuaModel> duas,
    Set<int> favorites,
  ) {
    if (duas.isEmpty || _currentIndex >= duas.length) return null;

    final dua = duas[_currentIndex];
    final isFavorite = favorites.contains(dua.duaId);

    return [
      const DuaReaderFontControlButton(),
      IconButton(
        tooltip: l10n.duaCopy,
        style: _actionIconStyle,
        icon: Icon(Icons.copy_outlined, size: _actionIconSize),
        onPressed: () => _copyDua(dua),
      ),
      IconButton(
        tooltip: l10n.duaShare,
        style: _actionIconStyle,
        icon: Icon(Icons.share_outlined, size: _actionIconSize),
        onPressed: () => _shareDua(dua),
      ),
      IconButton(
        tooltip: isFavorite ? l10n.duaFavRemove : l10n.duaFavAdd,
        style: _actionIconStyle,
        icon: Icon(
          isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          color: isFavorite ? AppColors.gold : null,
          size: _actionIconSize,
        ),
        onPressed: () => _toggleFavorite(dua),
      ),
      PopupMenuButton<String>(
        tooltip: l10n.duaReaderMore,
        padding: EdgeInsets.all(10.r),
        constraints: BoxConstraints(minWidth: 44.r, minHeight: 44.r),
        iconSize: _actionIconSize,
        icon: Icon(Icons.more_vert_rounded, size: _actionIconSize),
        onSelected: (action) => _handleMoreMenuAction(action, dua, duas),
        itemBuilder: (context) => _buildMoreMenuItems(l10n, duas),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duasAsync = ref.watch(duasByIdsProvider(widget.duaIds));
    final favorites = ref.watch(duaFavoritesProvider);
    final readerSettings = ref.watch(duaReaderSettingsProvider);

    return AppScaffold(
      handleExitBack: false,
      padding: EdgeInsets.zero,
      appBar: AppBar(
        leading: IconButton(
          style: _actionIconStyle,
          icon: Icon(Icons.arrow_back, size: _actionIconSize),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: duasAsync.maybeWhen(
          data: (duas) {
            if (duas.isEmpty || _currentIndex >= duas.length) {
              return Text(
                l10n.duaTitle,
                style: AppTextStyles.headlineMedium(context),
              );
            }
            return null;
          },
          orElse: () =>
              Text(l10n.duaTitle, style: AppTextStyles.headlineMedium(context)),
        ),
        actions: duasAsync.maybeWhen(
          data: (duas) => _buildActions(l10n, duas, favorites),
          orElse: () => null,
        ),
      ),
      body: duasAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => Center(
          child: Text(
            l10n.duaNoResults,
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
        data: (duas) {
          if (duas.isEmpty) {
            return Center(
              child: Text(
                l10n.duaNoResults,
                style: AppTextStyles.bodyMedium(context),
              ),
            );
          }

          final currentDua = duas[_currentIndex];

          return Stack(
            children: [
              Column(
                children: [
                  if (!_focusMode)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 8.h,
                      ),
                      color: AppColors.goldCard,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentDua.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _pageCounterText(
                              context,
                              _currentIndex + 1,
                              duas.length,
                            ),
                            style: AppTextStyles.label(
                              context,
                            ).copyWith(color: AppColors.gold, fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: duas.length,
                      onPageChanged: (index) =>
                          setState(() => _currentIndex = index),
                      itemBuilder: (context, index) =>
                          DuaPage(dua: duas[index], settings: readerSettings),
                    ),
                  ),
                ],
              ),
              if (currentDua.hasAudio)
                Positioned(
                  right: kDuaFloatingAudioButtonMargin.w,
                  bottom: kDuaFloatingAudioButtonMargin.h,
                  child: DuaFloatingAudioButton(
                    key: ValueKey(currentDua.duaId),
                    audioUrl: '$kDuaAudioBaseUrl${currentDua.audio}',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Text(text, style: AppTextStyles.bodyLarge(context)),
    );
  }
}

class _MoreMenuRow extends StatelessWidget {
  const _MoreMenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.r, color: AppColors.textSecondary),
        SizedBox(width: 12.w),
        Expanded(child: _MenuLabel(text: label)),
      ],
    );
  }
}
