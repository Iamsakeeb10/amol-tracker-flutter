/// Bengali score labels for the home screen widget.
String widgetScoreLabel(int score) {
  if (score <= 0) return 'আজ শুরু করো';
  if (score < 40) return 'চেষ্টা চালিয়ে যাও';
  if (score < 60) return 'মোটামুটি ভালো';
  if (score < 80) return 'ভালো করছো!';
  if (score < 100) return 'চমৎকার!';
  return 'মাশাআল্লাহ';
}
