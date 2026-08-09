import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/amal_fields.dart';
import '../../models/user_model.dart';
import '../../providers/amal_fields_provider.dart';
import '../../providers/auth_provider.dart';

/// Determines which amal fields are active, optional, or inactive for the
/// current entry based on the user's gender profile and special-time setting.
///
/// Decision table:
/// | Profile  | specialTimeActive | mainFields              | optionalFields            | inactiveSpecialTimeFields | activeFields           |
/// |----------|--------------------|-------------------------|---------------------------|---------------------------|------------------------|
/// | unset    | n/a                | all active fields       | (empty)                   | (empty)                   | mainFields             |
/// | male     | n/a                | all active fields       | (empty)                   | (empty)                   | mainFields             |
/// | female   | false              | non-femaleDeprioritized | femaleDeprioritized       | (empty)                   | main + optional        |
/// | female   | true               | non-disableDuringST     | (empty)                   | disableDuringSpecialTime  | mainFields             |
///
/// For female profiles, [mainFields] pins `fard_salah` first when present.
/// Optional deprioritized fields are typically `fard` and `takbir` only
/// (`fard_salah` stays main via `femaleDeprioritized: false`).
class AmalEntryPolicy {
  final List<AmalField> mainFields;
  final List<AmalField> optionalFields;
  final List<AmalField> inactiveSpecialTimeFields;
  final List<AmalField> activeFields;
  final bool isSpecialTimeActive;

  const AmalEntryPolicy({
    required this.mainFields,
    required this.optionalFields,
    required this.inactiveSpecialTimeFields,
    required this.activeFields,
    required this.isSpecialTimeActive,
  });

  List<String> get activeFieldIds =>
      activeFields.map((f) => f.id).toList();

  /// Builds a policy from the full field list and user profile.
  /// Uses the same sort order as [resolveAmalFields] (order then id).
  factory AmalEntryPolicy.from(UserAmalProfile profile, List<AmalField> fields, {bool specialTimeActive = false}) {
    final sorted = fields.where((f) => f.isActive && f.id.isNotEmpty).toList()
      ..sort((a, b) {
        final c = a.order.compareTo(b.order);
        return c != 0 ? c : a.id.compareTo(b.id);
      });

    // Apply genderVisibility before deprioritized / special-time splits.
    // Unset profiles see every field (no gender filtering).
    final all = sorted.where((f) {
      switch (f.genderVisibility) {
        case GenderVisibility.all:
          return true;
        case GenderVisibility.maleOnly:
          return profile != UserAmalProfile.female;
        case GenderVisibility.femaleOnly:
          return profile != UserAmalProfile.male;
      }
    }).toList();

    if (profile == UserAmalProfile.unset || profile == UserAmalProfile.male) {
      return AmalEntryPolicy(
        mainFields: all,
        optionalFields: const [],
        inactiveSpecialTimeFields: const [],
        activeFields: all,
        isSpecialTimeActive: false,
      );
    }

    // female
    if (specialTimeActive) {
      final inactive = all.where((f) => f.disableDuringSpecialTime).toList();
      final main = _pinFardSalahFirst(
        all.where((f) => !f.disableDuringSpecialTime).toList(),
      );
      return AmalEntryPolicy(
        mainFields: main,
        optionalFields: const [],
        inactiveSpecialTimeFields: inactive,
        activeFields: main,
        isSpecialTimeActive: true,
      );
    }

    // female + specialTime off
    final optional = all.where((f) => f.femaleDeprioritized).toList();
    final main = _pinFardSalahFirst(
      all.where((f) => !f.femaleDeprioritized).toList(),
    );
    return AmalEntryPolicy(
      mainFields: main,
      optionalFields: optional,
      inactiveSpecialTimeFields: const [],
      activeFields: [...main, ...optional],
      isSpecialTimeActive: false,
    );
  }
}

/// Pins `fard_salah` first when present; preserves relative order of the rest.
List<AmalField> _pinFardSalahFirst(List<AmalField> fields) {
  final pinned = <AmalField>[];
  final rest = <AmalField>[];
  for (final f in fields) {
    if (f.id == 'fard_salah') {
      pinned.add(f);
    } else {
      rest.add(f);
    }
  }
  return [...pinned, ...rest];
}

/// Provider that resolves the current [AmalEntryPolicy] from the live field
/// list and current user profile.
final amalEntryPolicyProvider = Provider<AmalEntryPolicy>((ref) {
  final fields = ref.watch(amalFieldsListProvider);
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user == null || fields.isEmpty) {
    return AmalEntryPolicy.from(UserAmalProfile.unset, fields);
  }
  return AmalEntryPolicy.from(
    user.amalProfile,
    fields,
    specialTimeActive: user.specialTimeActive,
  );
});

/// Whether special-time rules are active for today's entry.
/// Derived from [amalEntryPolicyProvider] so male/unset never report true.
final isSpecialTimeActiveForCurrentEntryProvider = Provider<bool>((ref) {
  return ref.watch(amalEntryPolicyProvider).isSpecialTimeActive;
});
