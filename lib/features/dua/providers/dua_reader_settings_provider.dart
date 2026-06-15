import 'package:riverpod/legacy.dart';

import '../../../core/services/local_storage_service.dart';

const _settingsKey = 'dua_reader_settings';

enum DuaTextSize { normal, medium, large }

extension DuaTextSizeScale on DuaTextSize {
  double get scaleFactor {
    switch (this) {
      case DuaTextSize.normal:
        return 1.0;
      case DuaTextSize.medium:
        return 1.12;
      case DuaTextSize.large:
        return 1.24;
    }
  }
}

class DuaReaderSettings {
  const DuaReaderSettings({
    this.textSize = DuaTextSize.normal,
    this.showIntroduction = true,
    this.showTransliteration = true,
    this.showTranslation = true,
    this.showReference = true,
  });

  final DuaTextSize textSize;
  final bool showIntroduction;
  final bool showTransliteration;
  final bool showTranslation;
  final bool showReference;

  double get textScale => textSize.scaleFactor;

  DuaReaderSettings copyWith({
    DuaTextSize? textSize,
    bool? showIntroduction,
    bool? showTransliteration,
    bool? showTranslation,
    bool? showReference,
  }) {
    return DuaReaderSettings(
      textSize: textSize ?? this.textSize,
      showIntroduction: showIntroduction ?? this.showIntroduction,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      showTranslation: showTranslation ?? this.showTranslation,
      showReference: showReference ?? this.showReference,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'textSize': textSize.index,
      'showIntroduction': showIntroduction,
      'showTransliteration': showTransliteration,
      'showTranslation': showTranslation,
      'showReference': showReference,
    };
  }

  factory DuaReaderSettings.fromJson(Map<String, dynamic> json) {
    final rawSize = json['textSize'] as int? ?? 0;
    final textSize = DuaTextSize.values[rawSize.clamp(0, DuaTextSize.values.length - 1)];
    return DuaReaderSettings(
      textSize: textSize,
      showIntroduction: json['showIntroduction'] as bool? ?? true,
      showTransliteration: json['showTransliteration'] as bool? ?? true,
      showTranslation: json['showTranslation'] as bool? ?? true,
      showReference: json['showReference'] as bool? ?? true,
    );
  }
}

class DuaReaderSettingsNotifier extends StateNotifier<DuaReaderSettings> {
  DuaReaderSettingsNotifier() : super(_loadSettings());

  static DuaReaderSettings _loadSettings() {
    final raw = LocalStorageService.getPref<Map<dynamic, dynamic>>(_settingsKey, const {});
    if (raw.isEmpty) return const DuaReaderSettings();
    return DuaReaderSettings.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> _persist() async {
    await LocalStorageService.setPref(_settingsKey, state.toJson());
  }

  Future<void> setTextSize(DuaTextSize size) async {
    state = state.copyWith(textSize: size);
    await _persist();
  }

  Future<void> decreaseTextSize() async {
    final index = state.textSize.index;
    if (index <= 0) return;
    await setTextSize(DuaTextSize.values[index - 1]);
  }

  Future<void> increaseTextSize() async {
    final index = state.textSize.index;
    if (index >= DuaTextSize.values.length - 1) return;
    await setTextSize(DuaTextSize.values[index + 1]);
  }

  Future<void> setShowIntroduction(bool value) async {
    state = state.copyWith(showIntroduction: value);
    await _persist();
  }

  Future<void> setShowTransliteration(bool value) async {
    state = state.copyWith(showTransliteration: value);
    await _persist();
  }

  Future<void> setShowTranslation(bool value) async {
    state = state.copyWith(showTranslation: value);
    await _persist();
  }

  Future<void> setShowReference(bool value) async {
    state = state.copyWith(showReference: value);
    await _persist();
  }
}

final duaReaderSettingsProvider =
    StateNotifierProvider<DuaReaderSettingsNotifier, DuaReaderSettings>(
  (ref) => DuaReaderSettingsNotifier(),
);
