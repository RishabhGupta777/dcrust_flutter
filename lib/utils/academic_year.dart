String? getAcademicYearLabel(String? yearFromStr, String? yearToStr) {
  if (yearFromStr == null || yearToStr == null) return null;
  final int? fromYear = int.tryParse(yearFromStr);
  final int? toYear = int.tryParse(yearToStr);
  
  if (fromYear == null || toYear == null || toYear <= fromYear) return null;

  final int duration = toYear - fromYear;
  final now = DateTime.now();

  int yearsElapsed = now.year - fromYear;
  // Session years typically start around July (month 7 in Dart)
  if (now.month < 7) {
    yearsElapsed -= 1;
  }

  final currentYear = yearsElapsed + 1;

  if (currentYear < 1) return 'Yet to Join';
  if (currentYear > duration) return 'Alumnus';
  if (currentYear == duration) return 'Final Year';

  const suffixes = {1: 'st', 2: 'nd', 3: 'rd'};
  final suffix = suffixes[currentYear] ?? 'th';
  
  return '$currentYear$suffix Year';
}
