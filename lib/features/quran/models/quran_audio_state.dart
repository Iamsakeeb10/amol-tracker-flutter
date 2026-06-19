class QuranAudioState {
  const QuranAudioState({
    this.surahId = 0,
    this.ayah = 0,
    this.qariId = '',
    this.isPlaying = false,
    this.isLoading = false,
    this.hasError = false,
    this.surahName = '',
    this.totalAyahs = 0,
  });

  final int surahId;
  final int ayah;
  final String qariId;
  final bool isPlaying;
  final bool isLoading;
  final bool hasError;
  final String surahName;
  final int totalAyahs;

  bool get isActive => surahId > 0 && ayah > 0;

  QuranAudioState copyWith({
    int? surahId,
    int? ayah,
    String? qariId,
    bool? isPlaying,
    bool? isLoading,
    bool? hasError,
    String? surahName,
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
      totalAyahs: totalAyahs ?? this.totalAyahs,
    );
  }
}
