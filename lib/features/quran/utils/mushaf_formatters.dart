/// Formats mushaf page numbers using Arabic-Indic digits (٠–٩).
String mushafArabicIndicDigits(int number) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number
      .toString()
      .split('')
      .map((d) => digits[int.parse(d)])
      .join();
}
