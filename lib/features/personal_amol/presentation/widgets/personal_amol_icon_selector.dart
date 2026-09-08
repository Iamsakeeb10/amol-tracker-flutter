import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'personal_amol_icon_picker.dart';
import 'personal_amol_icons.dart';

/// Horizontal scrollable Material-icon row with a dashed "see all" cell that
/// opens the full-screen [PersonalAmolIconPicker]. Emits the persisted icon
/// string via [onSelected] (see [encodePersonalAmolIcon]).
///
/// The currently selected icon is always pinned at index 0 so it stays visible
/// after picking from the full grid (including icons outside the default
/// preset window).
class PersonalAmolIconSelector extends ConsumerStatefulWidget {
  const PersonalAmolIconSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.presetCount = 32,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final int presetCount;

  @override
  ConsumerState<PersonalAmolIconSelector> createState() =>
      _PersonalAmolIconSelectorState();
}

class _PersonalAmolIconSelectorState
    extends ConsumerState<PersonalAmolIconSelector> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant PersonalAmolIconSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _scrollToStart();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  Future<void> _openFullPicker() async {
    final current = decodePersonalAmolIcon(widget.selected);
    final picked = await PersonalAmolIconPicker.show(context, selected: current);
    if (picked == null) return;
    widget.onSelected(encodePersonalAmolIcon(picked));
  }

  /// Preset row with [selected] forced to the front (injected if needed).
  List<IconData> _presetsWithSelectedFirst() {
    final presets =
        kPersonalAmolMaterialIcons.take(widget.presetCount).toList();
    final selectedIcon = decodePersonalAmolIcon(widget.selected);
    if (selectedIcon == null) return presets;
    presets.removeWhere((i) => i.codePoint == selectedIcon.codePoint);
    presets.insert(0, selectedIcon);
    if (presets.length > widget.presetCount) {
      presets.removeLast();
    }
    return presets;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final presets = _presetsWithSelectedFirst();
    final selectedCodePoint = decodePersonalAmolIcon(widget.selected)?.codePoint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.personalAmolIconLabel,
                style: AppTextStyles.bodyMedium(context),
              ),
            ),
            GestureDetector(
              onTap: _openFullPicker,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.personalAmolSeeAllIcons,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.gold,
                      size: 16.r,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 46.r,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: presets.length + 1,
            separatorBuilder: (_, _) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              if (index == presets.length) {
                return _allCell(context);
              }
              final icon = presets[index];
              final selected = icon.codePoint == selectedCodePoint;
              return GestureDetector(
                onTap: () =>
                    widget.onSelected(encodePersonalAmolIcon(icon)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 46.r,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.gold : AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: selected ? AppColors.gold : AppColors.cardBorder,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 22.r,
                    color: selected
                        ? AppColors.emeraldDeep
                        : AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _allCell(BuildContext context) {
    return GestureDetector(
      onTap: _openFullPicker,
      child: Container(
        width: 46.r,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.cardBorder,
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          Icons.grid_view_rounded,
          color: AppColors.textMuted,
          size: 20.r,
        ),
      ),
    );
  }
}
