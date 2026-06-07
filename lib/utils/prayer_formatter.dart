import 'package:intl/intl.dart';

class PrayerFormatter {
  static String formatTime(DateTime time, {bool use24h = true}) {
    return use24h
        ? DateFormat('HH:mm').format(time)
        : DateFormat('hh:mm a').format(time);
  }

  static String formatCountdown(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) return '--:--';
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
  }
}
