import 'dart:async';

import 'package:flutter/services.dart';
import 'package:riverpod/legacy.dart';

import '../core/services/analytics_service.dart';
import '../core/services/islamic_date_service.dart';
import '../core/services/local_storage_service.dart';
import '../models/dhikr_model.dart';

class DhikrState {
  const DhikrState({
    required this.selectedPreset,
    required this.count,
    required this.justCompleted,
    required this.customPresets,
    required this.todaySessions,
    required this.isLoading,
  });

  factory DhikrState.initial() {
    return DhikrState(
      selectedPreset: kBuiltInDhikrPresets.first,
      count: 0,
      justCompleted: false,
      customPresets: const [],
      todaySessions: const [],
      isLoading: true,
    );
  }

  final DhikrPreset selectedPreset;
  final int count;
  final bool justCompleted;
  final List<DhikrPreset> customPresets;
  final List<DhikrSession> todaySessions;
  final bool isLoading;

  List<DhikrPreset> get allPresets => [...kBuiltInDhikrPresets, ...customPresets];

  double get progress =>
      selectedPreset.target <= 0 ? 0 : count / selectedPreset.target;

  DhikrState copyWith({
    DhikrPreset? selectedPreset,
    int? count,
    bool? justCompleted,
    List<DhikrPreset>? customPresets,
    List<DhikrSession>? todaySessions,
    bool? isLoading,
  }) {
    return DhikrState(
      selectedPreset: selectedPreset ?? this.selectedPreset,
      count: count ?? this.count,
      justCompleted: justCompleted ?? this.justCompleted,
      customPresets: customPresets ?? this.customPresets,
      todaySessions: todaySessions ?? this.todaySessions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/*
Purpose:
Manage active dhikr counting, preset selection, custom presets, and daily completion logs.

Response:
Immutable [DhikrState] updates for UI: current count, selected preset, completion flag, sessions.

Business Rules:
- Built-in presets are fixed (33/33/34).
- Custom presets require non-empty unique names and target >= 1.
- Reaching target logs one session for today's Hijri date, then auto-resets after 1.5s.
- Manual reset clears count without logging.

Flow:
1. Load custom presets, selected preset id, and today's sessions from Hive.
2. On tap, increment count with light haptic; at target, log session and schedule reset.
3. Preset changes reset count unless same preset is re-selected.

Side Effects:
- Hive writes for sessions, custom presets, and selected preset id.
- Haptic feedback on tap and completion.

Failure Cases:
- Unknown saved preset id falls back to SubhanAllah.
- Haptic calls are wrapped so unsupported devices do not crash.
*/
class DhikrNotifier extends StateNotifier<DhikrState> {
  DhikrNotifier() : super(DhikrState.initial()) {
    _load();
  }

  Timer? _completionTimer;
  String? _activeHijriDate;

  String get _todayHijri => IslamicDateService.getCurrentIslamicDateStringSafe();

  Future<void> refreshFromStorage() async {
    final today = _todayHijri;
    final dayChanged =
        _activeHijriDate != null && _activeHijriDate != today;
    _activeHijriDate = today;
    final sessions = LocalStorageService.getDhikrSessionMaps(today)
        .map(DhikrSession.fromMap)
        .toList();
    _completionTimer?.cancel();
    final shouldResetCounter = dayChanged || state.justCompleted;
    state = state.copyWith(
      todaySessions: sessions,
      count: shouldResetCounter ? 0 : state.count,
      justCompleted: shouldResetCounter ? false : state.justCompleted,
    );
  }

  Future<void> _load() async {
    final customMaps = LocalStorageService.getCustomPresets();
    final customPresets = customMaps
        .map(DhikrPreset.fromMap)
        .where((p) => p.id.isNotEmpty && p.target > 0)
        .toList();
    final allPresets = [...kBuiltInDhikrPresets, ...customPresets];
    final savedId = LocalStorageService.getSelectedDhikrPresetId(kSubhanAllahId);
    final selected = allPresets.firstWhere(
      (p) => p.id == savedId,
      orElse: () => kBuiltInDhikrPresets.first,
    );
    _activeHijriDate = _todayHijri;
    final sessions = LocalStorageService.getDhikrSessionMaps(_todayHijri)
        .map(DhikrSession.fromMap)
        .toList();
    state = state.copyWith(
      customPresets: customPresets,
      selectedPreset: selected,
      todaySessions: sessions,
      isLoading: false,
    );
  }

  void tap() {
    if (state.isLoading || state.justCompleted) return;
    final nextCount = state.count + 1;
    if (nextCount < state.selectedPreset.target) {
      state = state.copyWith(count: nextCount);
      unawaited(_triggerHaptic(HapticFeedback.lightImpact));
      return;
    }
    unawaited(_completeSession());
  }

  Future<void> _completeSession() async {
    if (state.justCompleted) return;
    final preset = state.selectedPreset;
    final session = DhikrSession(
      presetId: preset.id,
      name: preset.isCustom ? (preset.customName ?? preset.id) : preset.id,
      target: preset.target,
      completedAt: DateTime.now().toUtc(),
      hijriDate: _todayHijri,
    );
    state = state.copyWith(
      count: preset.target,
      justCompleted: true,
      todaySessions: [...state.todaySessions, session],
    );
    unawaited(_triggerHaptic(HapticFeedback.mediumImpact));
    AnalyticsService.instance.logZikrCompleted(
      name: preset.isCustom ? (preset.customName ?? preset.id) : preset.id,
      count: preset.target,
    );
    await LocalStorageService.saveDhikrSession(_todayHijri, session.toMap());
    _completionTimer?.cancel();
    _completionTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      state = state.copyWith(count: 0, justCompleted: false);
    });
  }

  void reset() {
    _completionTimer?.cancel();
    state = state.copyWith(count: 0, justCompleted: false);
  }

  Future<void> selectPreset(DhikrPreset preset) async {
    if (preset.id == state.selectedPreset.id) return;
    _completionTimer?.cancel();
    await LocalStorageService.saveSelectedDhikrPresetId(preset.id);
    state = state.copyWith(
      selectedPreset: preset,
      count: 0,
      justCompleted: false,
    );
  }

  Future<String?> addCustomPreset({
    required String name,
    required int target,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'empty_name';
    if (target < 1) return 'invalid_target';
    if (_isDuplicateName(trimmed)) return 'duplicate_name';
    final preset = DhikrPreset(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      target: target,
      customName: trimmed,
      isCustom: true,
    );
    final updatedCustom = [...state.customPresets, preset];
    await LocalStorageService.saveCustomPresets(
      updatedCustom.map((p) => p.toMap()).toList(),
    );
    await LocalStorageService.saveSelectedDhikrPresetId(preset.id);
    _completionTimer?.cancel();
    state = state.copyWith(
      customPresets: updatedCustom,
      selectedPreset: preset,
      count: 0,
      justCompleted: false,
    );
    return null;
  }

  Future<void> deleteCustomPreset(String presetId) async {
    final updatedCustom =
        state.customPresets.where((p) => p.id != presetId).toList();
    await LocalStorageService.saveCustomPresets(
      updatedCustom.map((p) => p.toMap()).toList(),
    );
    var nextPreset = state.selectedPreset;
    if (nextPreset.id == presetId) {
      nextPreset = kBuiltInDhikrPresets.first;
      await LocalStorageService.saveSelectedDhikrPresetId(nextPreset.id);
    }
    _completionTimer?.cancel();
    state = state.copyWith(
      customPresets: updatedCustom,
      selectedPreset: nextPreset,
      count: 0,
      justCompleted: false,
    );
  }

  Future<void> _triggerHaptic(Future<void> Function() haptic) async {
    try {
      await haptic();
    } catch (_) {}
  }

  bool _isDuplicateName(String trimmed) {
    final normalized = trimmed.toLowerCase();
    const reserved = <String>{
      'subhanallah',
      'alhamdulillah',
      'allahu akbar',
      'সুবহানাল্লাহ',
      'আলহামদুলিল্লাহ',
      'আল্লাহু আকবার',
    };
    if (reserved.contains(normalized)) return true;
    return state.customPresets.any(
      (p) => (p.customName ?? '').trim().toLowerCase() == normalized,
    );
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    super.dispose();
  }
}

final dhikrProvider = StateNotifierProvider<DhikrNotifier, DhikrState>(
  (ref) => DhikrNotifier(),
);
