import 'package:riverpod/legacy.dart';

import '../core/services/local_storage_service.dart';

/// Tracks whether the optional amal section on the home screen is expanded.
///
/// Unlike [amalExpansionProvider], this state is persisted locally (Hive prefs)
/// so a user who keeps the optional amals open does not have to re-open the
/// section on every app launch.
class OptionalAmalExpansionNotifier extends StateNotifier<bool> {
  OptionalAmalExpansionNotifier() : super(_readPersisted());

  static const String prefKey = 'home_optional_amal_expanded';

  static bool _readPersisted() {
    try {
      return LocalStorageService.getPref<bool>(prefKey, false);
    } catch (_) {
      // Prefs box not open yet (e.g. in tests): fall back to collapsed.
      return false;
    }
  }

  /// Expands when collapsed and collapses when expanded, persisting the result.
  Future<void> toggle() => setExpanded(!state);

  /// Sets the expansion state and persists it for the next session.
  Future<void> setExpanded(bool value) async {
    if (state == value) return;
    state = value;
    try {
      await LocalStorageService.setPref(prefKey, value);
    } catch (_) {
      // Persistence is best-effort; the in-memory state stays correct.
    }
  }
}

/// Whether the home screen optional amal section is currently expanded.
final optionalAmalExpansionProvider =
    StateNotifierProvider<OptionalAmalExpansionNotifier, bool>(
      (ref) => OptionalAmalExpansionNotifier(),
    );
