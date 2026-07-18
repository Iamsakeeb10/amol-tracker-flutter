import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../../providers/amal_expansion_provider.dart';
import '../../../../providers/amal_provider.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/fard_prayer_expand_row.dart';

/// One amal row that rebuilds only when its own toggle value changes.
class AmalFieldTile extends ConsumerWidget {
  const AmalFieldTile({
    super.key,
    required this.uid,
    required this.field,
    required this.locale,
    this.readOnly = false,
    this.onTapDetails,
  });

  final String uid;
  final AmalField field;
  final String locale;
  final bool readOnly;
  final VoidCallback? onTapDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toggleValue = ref.watch(
      amalProvider(uid).select((s) => s.toggles[field.id]),
    );
    final notifier = ref.read(amalProvider(uid).notifier);

    if (field.type != AmalType.numeric) {
      return RepaintBoundary(
        child: AmalRow(
          field: field,
          locale: locale,
          done: toggleValue as bool? ?? false,
          onChanged: readOnly ? null : (_) => notifier.toggle(field.id),
          onTapDetails: onTapDetails,
          readOnly: readOnly,
        ),
      );
    }

    final numericValue = getNumericValue(toggleValue, field.maxValue);

    // Expansion is only offered for interactive, expansion-capable fields.
    final canExpand = !readOnly && field.supportsExpansion;
    final isExpanded = canExpand &&
        ref.watch(amalExpansionProvider.select((id) => id == field.id));

    // Independent per-prayer toggling: the persisted value stays a count, while
    // the lit-circle positions are tracked in AmalState (persisted to the local
    // draft) and reconciled with the count on any external change.
    Set<int> selection = const <int>{};
    if (canExpand) {
      final stored = ref.watch(
        amalProvider(uid).select((s) => s.prayerSelections[field.id]),
      );
      selection = resolvePrayerSelection(stored, numericValue, field.maxValue);
    }

    final row = AmalRow(
      field: field,
      locale: locale,
      done: numericValue > 0,
      numericValue: numericValue,
      onNumericChanged:
          readOnly ? null : (v) => notifier.setNumeric(field.id, v),
      onTapDetails: onTapDetails,
      readOnly: readOnly,
      expandable: canExpand,
      isExpanded: isExpanded,
      onToggleExpand: canExpand
          ? () => ref.read(amalExpansionProvider.notifier).toggle(field.id)
          : null,
      expandedContent: canExpand
          ? FardPrayerExpandRow(
              selectedIndices: selection,
              slotCount: field.maxValue,
              onToggleIndex: (index) => notifier.togglePrayer(field.id, index),
            )
          : null,
    );

    // While expanded, tapping anywhere outside this tile collapses it.
    // TapRegion routes pointer-downs globally (independent of the gesture
    // arena / scrollables), so this is reliable across the whole screen.
    final child = isExpanded
        ? TapRegion(
            onTapOutside: (_) =>
                ref.read(amalExpansionProvider.notifier).collapse(),
            child: row,
          )
        : row;

    return RepaintBoundary(child: child);
  }
}
