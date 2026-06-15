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
import '../widgets/dua_floating_audio_button.dart';
import '../widgets/dua_page.dart';

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

  String _pageCounterText(BuildContext context, int current, int total) {
    final l10n = AppLocalizations.of(context)!;
    if (Localizations.localeOf(context).languageCode == 'bn') {
      return '${toBengaliNumeral(current)} / ${toBengaliNumeral(total)}';
    }
    return l10n.duaPageCounter(current, total);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duasAsync = ref.watch(duasByIdsProvider(widget.duaIds));
    final favorites = ref.watch(duaFavoritesProvider);

    return AppScaffold(
      handleExitBack: false,
      padding: EdgeInsets.zero,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: duasAsync.maybeWhen(
          data: (duas) {
            if (duas.isEmpty || _currentIndex >= duas.length) {
              return Text(l10n.duaTitle, style: AppTextStyles.headlineMedium(context));
            }
            return null;
          },
          orElse: () => Text(l10n.duaTitle, style: AppTextStyles.headlineMedium(context)),
        ),
        actions: duasAsync.maybeWhen(
          data: (duas) {
            if (duas.isEmpty || _currentIndex >= duas.length) return null;
            final dua = duas[_currentIndex];
            final isFavorite = favorites.contains(dua.duaId);
            return [
              IconButton(
                tooltip: l10n.duaCopy,
                icon: Icon(Icons.copy_outlined, size: 20.r),
                onPressed: () => _copyDua(dua),
              ),
              IconButton(
                tooltip: l10n.duaShare,
                icon: Icon(Icons.share_outlined, size: 20.r),
                onPressed: () => _shareDua(dua),
              ),
              IconButton(
                tooltip: isFavorite ? l10n.duaFavRemove : l10n.duaFavAdd,
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFavorite ? AppColors.gold : null,
                  size: 22.r,
                ),
                onPressed: () => _toggleFavorite(dua),
              ),
            ];
          },
          orElse: () => null,
        ),
      ),
      body: duasAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
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
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
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
                          style: AppTextStyles.label(context).copyWith(
                            color: AppColors.gold,
                            fontSize: 12.sp,
                          ),
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
                      itemBuilder: (context, index) => DuaPage(dua: duas[index]),
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
