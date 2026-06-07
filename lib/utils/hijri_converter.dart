/// Gregorian ↔ Hijri (tabular Islamic calendar, epoch JDN 1948440 = 16 Jul 622 CE Julian).
/// Verified: 7 Jul 2024 CE = 1 Muharram 1446 AH ✓
class HijriDate {
  final int year;
  final int month;
  final int day;

  const HijriDate(this.year, this.month, this.day);

  static const _epoch = 1948440;

  static const _monthNames = [
    'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani",
    "Jumada al-Awwal", "Jumada al-Thani", 'Rajab', "Sha'ban",
    'Ramadan', 'Chawwal', "Dhul Qi'da", 'Dhul Hijja',
  ];

  String get monthName => _monthNames[month - 1];

  String format() => '$day $monthName $year';
  String formatMonthYear() => '$monthName $year';

  static HijriDate fromGregorian(DateTime date) {
    final jdn = _toJDN(date.year, date.month, date.day);
    final d = jdn - _epoch;

    int y = (30 * d + 10646) ~/ 10631;
    if (y < 1) y = 1;
    while (_yearStart(y + 1) <= d) {
      y++;
    }

    final dayOfYear = d - _yearStart(y);
    var m = 1;
    while (m < 12 && _monthOffset(m + 1) <= dayOfYear) {
      m++;
    }

    return HijriDate(y, m, dayOfYear - _monthOffset(m) + 1);
  }

  // Julian Day Number for Gregorian date (valid post-1582)
  static int _toJDN(int y, int m, int d) {
    if (m <= 2) {
      y--;
      m += 12;
    }
    final a = y ~/ 100;
    final b = 2 - a + a ~/ 4;
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d + b - 1524;
  }

  // Days from Islamic epoch to first day of Hijri year y
  static int _yearStart(int y) {
    final n = y - 1;
    return 354 * n + (11 * n + 3) ~/ 30;
  }

  // Days from start of year to start of month m (odd months = 30 days, even = 29)
  static int _monthOffset(int m) => 29 * (m - 1) + m ~/ 2;
}
