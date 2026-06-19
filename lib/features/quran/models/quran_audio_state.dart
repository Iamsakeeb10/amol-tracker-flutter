class QuranAudioState {
  const QuranAudioState({
    this.surahId = 0,
    this.ayah = 0,
    this.qariId = '',
    this.isPlaying = false,
    this.isLoading = false,
    this.hasError = false,
    this.surahName = '',
    this.surahNameBn = '',
    this.totalAyahs = 0,
  });

  final int surahId;
  final int ayah;
  final String qariId;
  final bool isPlaying;
  final bool isLoading;
  final bool hasError;
  /// Transliteration name (e.g. Al-Fatihah).
  final String surahName;
  /// Bengali display name.
  final String surahNameBn;
  final int totalAyahs;

  bool get isActive => surahId > 0 && ayah > 0;

  /// Primary label for the current app locale.
  String displayName(String languageCode) {
    if (languageCode == 'bn' && surahNameBn.isNotEmpty) return surahNameBn;
    return surahName;
  }

  QuranAudioState copyWith({
    int? surahId,
    int? ayah,
    String? qariId,
    bool? isPlaying,
    bool? isLoading,
    bool? hasError,
    String? surahName,
    String? surahNameBn,
    int? totalAyahs,
  }) {
    return QuranAudioState(
      surahId: surahId ?? this.surahId,
      ayah: ayah ?? this.ayah,
      qariId: qariId ?? this.qariId,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      surahName: surahName ?? this.surahName,
      surahNameBn: surahNameBn ?? this.surahNameBn,
      totalAyahs: totalAyahs ?? this.totalAyahs,
    );
  }
}
