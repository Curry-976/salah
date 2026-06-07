import 'package:flutter/foundation.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_model.dart';
import 'notification_service.dart';

class PrayerService extends ChangeNotifier {
  PrayerTimes? _prayerTimes;
  PrayerSettings _settings = const PrayerSettings();
  List<PrayerTime> _todayPrayers = [];
  PrayerTime? _nextPrayer;
  Duration _timeToNext = Duration.zero;

  PrayerTimes? get prayerTimes => _prayerTimes;
  PrayerSettings get settings => _settings;
  List<PrayerTime> get todayPrayers => _todayPrayers;
  PrayerTime? get nextPrayer => _nextPrayer;
  Duration get timeToNext => _timeToNext;

  Future<void> calculate(double latitude, double longitude) async {
    final coords = Coordinates(latitude, longitude);
    final params = _settings.method.getParameters();
    params.madhab = _settings.madhab;

    final date = DateComponents.from(DateTime.now());
    _prayerTimes = PrayerTimes(coords, date, params);

    _buildPrayerList();
    _findNextPrayer();
    await _scheduleNotifications();
    notifyListeners();
  }

  void _buildPrayerList() {
    if (_prayerTimes == null) return;
    final now = DateTime.now();
    final times = [
      PrayerTime(name: PrayerName.fajr, time: _prayerTimes!.fajr),
      PrayerTime(name: PrayerName.sunrise, time: _prayerTimes!.sunrise),
      PrayerTime(name: PrayerName.dhuhr, time: _prayerTimes!.dhuhr),
      PrayerTime(name: PrayerName.asr, time: _prayerTimes!.asr),
      PrayerTime(name: PrayerName.maghrib, time: _prayerTimes!.maghrib),
      PrayerTime(name: PrayerName.isha, time: _prayerTimes!.isha),
    ];

    _todayPrayers = times
        .map((p) => PrayerTime(
              name: p.name,
              time: p.time,
              isPast: p.time.isBefore(now),
            ))
        .toList();
  }

  void _findNextPrayer() {
    final now = DateTime.now();
    for (final prayer in _todayPrayers) {
      if (prayer.time.isAfter(now)) {
        _nextPrayer = PrayerTime(
          name: prayer.name,
          time: prayer.time,
          isNext: true,
        );
        _timeToNext = prayer.time.difference(now);
        return;
      }
    }
    // All prayers passed, next is Fajr tomorrow
    _nextPrayer = null;
    _timeToNext = Duration.zero;
  }

  void updateTimeToNext() {
    if (_nextPrayer == null) return;
    final remaining = _nextPrayer!.time.difference(DateTime.now());
    if (remaining.isNegative) {
      _findNextPrayer();
    } else {
      _timeToNext = remaining;
    }
    notifyListeners();
  }

  Future<void> updateSettings(PrayerSettings newSettings) async {
    _settings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('calc_method', _settings.method.index);
    await prefs.setInt('madhab', _settings.madhab.index);
    await prefs.setBool('notifications', _settings.notificationsEnabled);
    notifyListeners();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final methodIndex = prefs.getInt('calc_method') ?? 3;
    final madhabIndex = prefs.getInt('madhab') ?? 0;
    final notifications = prefs.getBool('notifications') ?? true;

    _settings = PrayerSettings(
      method: CalculationMethod.values[methodIndex.clamp(0, CalculationMethod.values.length - 1)],
      madhab: Madhab.values[madhabIndex.clamp(0, Madhab.values.length - 1)],
      notificationsEnabled: notifications,
    );
  }

  Future<void> _scheduleNotifications() async {
    if (!_settings.notificationsEnabled || _prayerTimes == null) return;
    await NotificationService.instance.scheduleAllPrayers(_todayPrayers);
  }
}
