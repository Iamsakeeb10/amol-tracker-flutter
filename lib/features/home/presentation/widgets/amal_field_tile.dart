import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../../providers/amal_provider.dart';
import '../../../../shared/widgets/amal_row.dart';

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

    return RepaintBoundary(
      child: field.type == AmalType.numeric
          ? AmalRow(
              field: field,
              locale: locale,
              done: getNumericValue(toggleValue, field.maxValue) > 0,
              numericValue: getNumericValue(toggleValue, field.maxValue),
              onNumericChanged: readOnly
                  ? null
                  : (v) => notifier.setNumeric(field.id, v),
              onTapDetails: onTapDetails,
              readOnly: readOnly,
            )
          : AmalRow(
              field: field,
              locale: locale,
              done: toggleValue as bool? ?? false,
              onChanged: readOnly ? null : (_) => notifier.toggle(field.id),
              onTapDetails: onTapDetails,
              readOnly: readOnly,
            ),
    );
  }
}
