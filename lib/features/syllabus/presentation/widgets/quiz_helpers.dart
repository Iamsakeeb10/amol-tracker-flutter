import '../../../../l10n/app_localizations.dart';

String formatQuizDuration(int totalSeconds) {
  if (totalSeconds <= 0) return '0:00';
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String formatQuizTimeLimit(AppLocalizations l10n, int seconds) {
  if (seconds <= 0) return l10n.syllabusQuizNoTimeLimit;
  return formatQuizDuration(seconds);
}

String quizOptionLetter(int index) {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  if (index < 0 || index >= letters.length) return '${index + 1}';
  return letters[index];
}

double quizProgressValue(int currentIndex, int totalQuestions) {
  if (totalQuestions <= 0) return 0;
  return (currentIndex + 1) / totalQuestions;
}
