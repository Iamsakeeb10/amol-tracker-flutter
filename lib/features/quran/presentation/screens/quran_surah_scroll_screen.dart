import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../models/quran_audio_state.dart';
import '../../models/quran_ayah.dart';
import '../../providers/quran_audio_provider.dart';
import '../../providers/quran_performance_provider.dart';
import '../../providers/quran_reading_prefs_provider.dart';
import '../../providers/quran_surah_ayahs_provider.dart';
import '../../providers/quran_surah_provider.dart';
import '../../utils/quran_tap_targets.dart';
import '../widgets/ayah_card_widget.dart';
import '../widgets/quran_audio_mini_bar.dart';
import '../widgets/quran_floating_audio_button.dart';
import '../widgets/translation_panel.dart';

class QuranSurahScrollScreen extends ConsumerStatefulWidget {
  const QuranSurahScrollScreen({super.key, required this.surahId});

  final int surahId;

  @override
  ConsumerState<QuranSurahScrollScreen> createState() =>
      _QuranSurahScrollScreenState();
}

class _QuranSurahScrollScreenState
    extends ConsumerState<QuranSurahScrollScreen> {
  final _scrollController = ScrollController();
  final _ayahKeys = <int, GlobalKey>{};
  List<QuranAyah> _ayahs = const [];
  bool _programmaticScroll = false;
  bool _scrollInProgress = false;
  int? _pendingScrollAyah;
  Timer? _scrollSaveTimer;
  int? _pendingAyahSave;
  DateTime? _entryTime;

  @override
  void initState() {
    super.initState();
    _entryTime = DateTime.now();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final surahs = ref.read(quranSurahListProvider).asData?.value;
      if (surahs != null) {
        final surah = surahs.firstWhere(
          (s) => s.id == widget.surahId,
          orElse: () => surahs.first,
        );
        AnalyticsService.instance.logSurahOpened(
          name: surah.nameTransliteration,
          page: surah.startPage,
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadAyahsFromProvider(),
    );
  }

  void _ensureAyahsLoaded(List<QuranAyah> ayahs) {
    if (ayahs.isEmpty) return;
    _ayahs = ayahs;
    _syncAyahKeys(ayahs);
  }

  void _loadAyahsFromProvider() {
    if (!mounted) return;
    final ayahs = ref
        .read(quranSurahAyahsProvider(widget.surahId))
        .asData
        ?.value;
    if (ayahs != null) {
      _ensureAyahsLoaded(ayahs);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollSaveTimer?.cancel();
    _flushPendingAyahSave();
    _logReadingSession();
    _scrollController.dispose();
    super.dispose();
  }

  void _logReadingSession() {
    if (_entryTime == null) return;
    final duration = DateTime.now().difference(_entryTime!);
    final minutes = duration.inMinutes;
    if (minutes < 1) return;
    AnalyticsService.instance.logReadingSessionCompleted(
      minutes: minutes,
      pages: _ayahs.length,
    );
  }

  void _flushPendingAyahSave() {
    final ayah = _pendingAyahSave;
    if (ayah == null) return;
    unawaited(
      ref
          .read(quranReadingPrefsProvider.notifier)
          .setLastReadAyah(widget.surahId, ayah),
    );
    _pendingAyahSave = null;
  }

  void _scheduleAyahSave(int ayah) {
    _pendingAyahSave = ayah;
    _scrollSaveTimer?.cancel();
    _scrollSaveTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _flushPendingAyahSave();
    });
  }

  void _onScroll() {
    if (_programmaticScroll || !_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final viewport = _scrollController.position.viewportDimension;
    final center = offset + (viewport * 0.35);

    int? closestAyah;
    double? closestDistance;

    for (final entry in _ayahKeys.entries) {
      final context = entry.value.currentContext;
      if (context == null) continue;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;

      final position = box.localToGlobal(Offset.zero);
      final distance = (position.dy - center).abs();
      if (closestDistance == null || distance < closestDistance) {
        closestDistance = distance;
        closestAyah = entry.key;
      }
    }

    if (closestAyah != null) {
      _scheduleAyahSave(closestAyah);
    }
  }

  GlobalKey _keyForAyah(int ayah) => _ayahKeys.putIfAbsent(ayah, GlobalKey.new);

  void _syncAyahKeys(List<QuranAyah> ayahs) {
    for (final ayah in ayahs) {
      _keyForAyah(ayah.ayah);
    }
  }

  int _indexForAyah(int ayah) => _ayahs.indexWhere((item) => item.ayah == ayah);

  Future<void> _jumpNearAyahIndex(int index) async {
    if (!_scrollController.hasClients || _ayahs.length <= 1) return;

    final position = _scrollController.position;
    final fraction = index / (_ayahs.length - 1);
    final target = (fraction * position.maxScrollExtent).clamp(
      0.0,
      position.maxScrollExtent,
    );

    position.jumpTo(target);
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _scrollToAyah(int ayah, {bool animate = true}) async {
    if (_scrollInProgress) {
      _pendingScrollAyah = ayah;
      return;
    }

    _scrollInProgress = true;
    _programmaticScroll = true;
    try {
      if (_ayahs.isEmpty) return;

      final index = _indexForAyah(ayah);
      if (index < 0) return;

      _keyForAyah(ayah);

      BuildContext? targetContext = _ayahKeys[ayah]?.currentContext;

      if (targetContext == null) {
        await _jumpNearAyahIndex(index);

        for (var attempt = 0; attempt < 10; attempt++) {
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted) return;

          targetContext = _ayahKeys[ayah]?.currentContext;
          if (targetContext != null) break;

          // maxScrollExtent grows as items are laid out — re-jump once midway.
          if (attempt == 4) {
            await _jumpNearAyahIndex(index);
          }
        }
      }

      if (targetContext == null || !mounted) return;

      await Scrollable.ensureVisible(
        targetContext,
        duration: animate ? const Duration(milliseconds: 400) : Duration.zero,
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    } finally {
      _programmaticScroll = false;
      _scrollInProgress = false;

      final pending = _pendingScrollAyah;
      _pendingScrollAyah = null;
      if (pending != null && pending != ayah && mounted) {
        unawaited(_scrollToAyah(pending, animate: animate));
      }
    }
  }

  Future<void> _showJumpToAyahDialog(int maxAyah) async {
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _JumpToAyahDialog(maxAyah: maxAyah),
    );

    if (result == null || !mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    await _scrollToAyah(result);
  }

  void _onJumpToAyahPressed() {
    final ayahs =
        ref.read(quranSurahAyahsProvider(widget.surahId)).asData?.value ??
        _ayahs;
    if (ayahs.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.quranJumpToAyahHint),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    unawaited(_showJumpToAyahDialog(ayahs.last.ayah));
  }

  void _copyAyah(BuildContext context, QuranAyah ayah) {
    final l10n = AppLocalizations.of(context)!;
    final buffer = StringBuffer(ayah.textAr);
    final translation = ayah.translation?.trim();
    if (translation != null && translation.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln()
        ..write(translation);
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.quranAyahCopied),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final surahAsync = ref.watch(quranSurahByIdProvider(widget.surahId));
    final ayahsAsync = ref.watch(quranSurahAyahsProvider(widget.surahId));
    final perf = ref.watch(quranPerformanceProvider);
    final showFloatingAudioButton = !ref.watch(
      quranAudioProvider.select(
        (state) => state.isActive && state.surahId == widget.surahId,
      ),
    );

    ref.listen<AsyncValue<List<QuranAyah>>>(
      quranSurahAyahsProvider(widget.surahId),
      (previous, next) {
        next.whenData(_ensureAyahsLoaded);
      },
    );

    ref.listen<QuranAudioState>(quranAudioProvider, (previous, next) {
      if (next.surahId != widget.surahId || next.ayah <= 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_scrollToAyah(next.ayah));
      });
    });

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          style: QuranTapTargets.iconButtonStyle(),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: surahAsync.when(
          data: (surah) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                surah?.displayName(languageCode) ?? l10n.quranTitle,
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              if (surah != null)
                Text(
                  l10n.quranAyahs(surah.ayahCount),
                  style: AppTextStyles.bodySmall(context),
                ),
            ],
          ),
          loading: () => Text(l10n.quranTitle),
          error: (_, __) => Text(l10n.quranTitle),
        ),
        actions: [
          IconButton(
            tooltip: l10n.quranJumpToAyah,
            style: QuranTapTargets.iconButtonStyle(),
            onPressed: _onJumpToAyahPressed,
            icon: Icon(Icons.keyboard_rounded, size: 22.r),
          ),
          IconButton(
            tooltip: l10n.settings,
            style: QuranTapTargets.iconButtonStyle(),
            onPressed: () => showTranslationPanel(context),
            icon: Icon(Icons.settings_outlined, size: 22.r),
          ),
        ],
      ),
      bottomNavigationBar: const QuranAudioMiniBar(),
      body: ayahsAsync.when(
        loading: () => ListView.builder(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
          itemCount: 6,
          itemBuilder: (context, index) => Container(
            height: 96.h,
            margin: EdgeInsets.only(bottom: 10.h),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(AppRadius.lg.r),
            ),
          ),
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (ayahs) {
          return Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  20.w,
                  8.h,
                  20.w,
                  quranSurahScrollBottomPadding(
                    showFloatingAudioButton: showFloatingAudioButton,
                  ),
                ),
                cacheExtent: perf.surahScrollCacheExtent,
                itemCount: ayahs.length,
                itemBuilder: (context, index) {
                  final ayah = ayahs[index];
                  return AyahCardWidget(
                    key: _keyForAyah(ayah.ayah),
                    surahId: widget.surahId,
                    ayah: ayah,
                    onTap: () async {
                      final surah = await ref.read(
                        quranSurahByIdProvider(widget.surahId).future,
                      );
                      if (surah == null) return;
                      await ref
                          .read(quranAudioProvider.notifier)
                          .playSurah(surah, startAyah: ayah.ayah);
                    },
                    onLongPress: () => _copyAyah(context, ayah),
                  );
                },
              ),
              if (showFloatingAudioButton)
                Positioned(
                  right: kQuranFloatingAudioButtonMargin.w,
                  bottom: kQuranFloatingAudioButtonMargin.h,
                  child: QuranFloatingAudioButton(
                    key: ValueKey(widget.surahId),
                    surahId: widget.surahId,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _JumpToAyahDialog extends StatefulWidget {
  const _JumpToAyahDialog({required this.maxAyah});

  final int maxAyah;

  @override
  State<_JumpToAyahDialog> createState() => _JumpToAyahDialogState();
}

class _JumpToAyahDialogState extends State<_JumpToAyahDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final ayah = int.tryParse(_controller.text.trim());
    if (ayah == null || ayah < 1 || ayah > widget.maxAyah) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.quranJumpToAyahHint),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.of(context).pop(ayah);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AppColors.emeraldMid,
      title: Text(
        l10n.quranJumpToAyah,
        style: AppTextStyles.headlineMedium(context),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(hintText: l10n.quranJumpToAyahHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.quranJumpToAyah)),
      ],
    );
  }
}
