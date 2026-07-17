import 'package:riverpod/legacy.dart';

/// Tracks which amal field (by id) is currently expanded on the home screen.
///
/// Only one field can be expanded at a time. The state is intentionally
/// session-only (not persisted): navigating away or restarting resets it to
/// collapsed for a clean home view.
class AmalExpansionNotifier extends StateNotifier<String?> {
  AmalExpansionNotifier() : super(null);

  /// Expand the given field, collapsing any other currently-expanded field.
  void expand(String fieldId) {
    if (state == fieldId) return;
    state = fieldId;
  }

  /// Collapse the currently-expanded field, if any.
  void collapse() {
    if (state == null) return;
    state = null;
  }

  /// Toggle expansion for [fieldId]: expand if collapsed, collapse if already
  /// expanded.
  void toggle(String fieldId) {
    state = state == fieldId ? null : fieldId;
  }

  /// Collapse if the currently-expanded field is no longer available (e.g. the
  /// admin removed it or the field list changed).
  void collapseIfMissing(Set<String> availableFieldIds) {
    final current = state;
    if (current != null && !availableFieldIds.contains(current)) {
      state = null;
    }
  }
}

/// Currently-expanded amal field id, or null when everything is collapsed.
final amalExpansionProvider =
    StateNotifierProvider<AmalExpansionNotifier, String?>(
      (ref) => AmalExpansionNotifier(),
    );
